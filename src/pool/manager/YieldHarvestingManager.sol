// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IVaultETH} from "../../interfaces/vault/IVaultETH.sol";
import {IColEUR} from "../../interfaces/tokenization/IColEUR.sol";
import {IChainlinkOracleManager} from "../../interfaces/chainlink/IChainlinkOracleManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract YieldHarvestingManager is
    Initializable,
    AccessManagedUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    struct YieldHarvestingManagerStorage {
        // Core contracts
        IVaultETH _vaultETH;
        IColEUR _colEUR;
        IChainlinkOracleManager _oracleManager;
        IERC20 _eurcToken;
        // Harvesting configuration
        uint256 _harvestInterval; // Minimum time between harvests
        uint256 _minYieldThreshold; // Minimum yield amount to trigger harvest
        uint256 _lastHarvestTime;
        uint256 _protocolFeeRate; // Fee rate in basis points (e.g., 1000 = 10%)
        address _protocolTreasury;
        // Performance tracking
        uint256 _totalYieldHarvested;
        uint256 _totalFeesCollected;
        uint256 _totalDistributedToColEUR;
        // Emergency controls
        bool _harvestingPaused;
        mapping(address => bool) _authorizedKeepers;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.YieldHarvestingManager")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant YieldHarvestingManagerStorageLocation =
        0x1c03345a3baecbfa5f76c98daacb964c084ba41883ee9de5881a16f46ba4f200;

    function _getYieldHarvestingManagerStorage()
        private
        pure
        returns (YieldHarvestingManagerStorage storage $)
    {
        assembly {
            $.slot := YieldHarvestingManagerStorageLocation
        }
    }

    // Events
    event YieldHarvestExecuted(
        uint256 indexed timestamp,
        uint256 totalYieldETH,
        uint256 eurcHarvested,
        uint256 protocolFee,
        uint256 distributedToColEUR
    );

    event HarvestingConfigurationUpdated(
        uint256 harvestInterval,
        uint256 minYieldThreshold,
        uint256 protocolFeeRate,
        address protocolTreasury
    );

    event KeeperAdded(address indexed keeper);
    event KeeperRemoved(address indexed keeper);
    event HarvestingPaused(bool paused);
    event EmergencyYieldWithdrawal(address indexed token, uint256 amount);

    // Errors
    error YieldHarvestingManager_NotAuthorizedKeeper();
    error YieldHarvestingManager_HarvestingPaused();
    error YieldHarvestingManager_InsufficientYield();
    error YieldHarvestingManager_TooEarlyToHarvest();
    error YieldHarvestingManager_InvalidConfiguration();
    error YieldHarvestingManager_InvalidVault();
    error YieldHarvestingManager_InvalidColEUR();

    modifier onlyKeeper() {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();
        if (!$._authorizedKeepers[msg.sender] && msg.sender != authority()) {
            revert YieldHarvestingManager_NotAuthorizedKeeper();
        }
        _;
    }

    modifier whenNotPaused() {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();
        if ($._harvestingPaused)
            revert YieldHarvestingManager_HarvestingPaused();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        address vaultETH,
        address colEUR,
        address oracleManager,
        address eurcToken
    ) public initializer {
        if (vaultETH == address(0))
            revert YieldHarvestingManager_InvalidVault();
        if (colEUR == address(0)) revert YieldHarvestingManager_InvalidColEUR();

        __AccessManaged_init(initialAuthority);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();
        $._vaultETH = IVaultETH(vaultETH);
        $._colEUR = IColEUR(colEUR);
        $._oracleManager = IChainlinkOracleManager(oracleManager);
        $._eurcToken = IERC20(eurcToken);

        // Default configuration
        $._harvestInterval = 1 days;
        $._minYieldThreshold = 0.1 ether; // 0.1 ETH equivalent
        $._protocolFeeRate = 1000; // 10%
        $._harvestingPaused = false;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    // ============ Configuration Functions ============

    function setHarvestingConfiguration(
        uint256 harvestInterval,
        uint256 minYieldThreshold,
        uint256 protocolFeeRate,
        address protocolTreasury
    ) external restricted {
        if (protocolFeeRate > 5000)
            revert YieldHarvestingManager_InvalidConfiguration(); // Max 50%

        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();
        $._harvestInterval = harvestInterval;
        $._minYieldThreshold = minYieldThreshold;
        $._protocolFeeRate = protocolFeeRate;
        $._protocolTreasury = protocolTreasury;

        emit HarvestingConfigurationUpdated(
            harvestInterval,
            minYieldThreshold,
            protocolFeeRate,
            protocolTreasury
        );
    }

    function addKeeper(address keeper) external restricted {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();
        $._authorizedKeepers[keeper] = true;
        emit KeeperAdded(keeper);
    }

    function removeKeeper(address keeper) external restricted {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();
        $._authorizedKeepers[keeper] = false;
        emit KeeperRemoved(keeper);
    }

    function pauseHarvesting(bool paused) external restricted {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();
        $._harvestingPaused = paused;
        emit HarvestingPaused(paused);
    }

    // ============ Yield Harvesting Functions ============

    function canHarvest()
        external
        view
        returns (
            bool canHarvestNow,
            uint256 estimatedYield,
            string memory reason
        )
    {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();

        if ($._harvestingPaused) {
            return (false, 0, "Harvesting is paused");
        }

        if (block.timestamp < $._lastHarvestTime + $._harvestInterval) {
            return (false, 0, "Too early to harvest");
        }

        (uint256 totalYield, ) = $._vaultETH.calculateTotalYield();

        if (totalYield < $._minYieldThreshold) {
            return (false, totalYield, "Insufficient yield");
        }

        return (true, totalYield, "Ready to harvest");
    }

    function executeHarvest() external nonReentrant onlyKeeper whenNotPaused {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();

        // Check timing
        if (block.timestamp < $._lastHarvestTime + $._harvestInterval) {
            revert YieldHarvestingManager_TooEarlyToHarvest();
        }

        // Check yield threshold
        (uint256 totalYieldETH, ) = $._vaultETH.calculateTotalYield();
        if (totalYieldETH < $._minYieldThreshold) {
            revert YieldHarvestingManager_InsufficientYield();
        }

        // Execute harvest
        uint256 eurcHarvested = $._vaultETH.harvestYield();

        // Calculate protocol fee
        uint256 protocolFee = (eurcHarvested * $._protocolFeeRate) / 10000;
        uint256 distributionAmount = eurcHarvested - protocolFee;

        // Transfer protocol fee to treasury
        if (protocolFee > 0 && $._protocolTreasury != address(0)) {
            $._eurcToken.safeTransferFrom(
                address($._vaultETH),
                $._protocolTreasury,
                protocolFee
            );
        }

        // The remaining EURC should already be distributed to ColEUR by the vault

        // Update tracking
        $._lastHarvestTime = block.timestamp;
        $._totalYieldHarvested += totalYieldETH;
        $._totalFeesCollected += protocolFee;
        $._totalDistributedToColEUR += distributionAmount;

        emit YieldHarvestExecuted(
            block.timestamp,
            totalYieldETH,
            eurcHarvested,
            protocolFee,
            distributionAmount
        );
    }

    function forceHarvest() external nonReentrant restricted {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();

        // Execute harvest regardless of timing/threshold constraints
        uint256 eurcHarvested = $._vaultETH.harvestYield();

        if (eurcHarvested > 0) {
            // Calculate protocol fee
            uint256 protocolFee = (eurcHarvested * $._protocolFeeRate) / 10000;
            uint256 distributionAmount = eurcHarvested - protocolFee;

            // Transfer protocol fee to treasury
            if (protocolFee > 0 && $._protocolTreasury != address(0)) {
                $._eurcToken.safeTransferFrom(
                    address($._vaultETH),
                    $._protocolTreasury,
                    protocolFee
                );
            }

            // Update tracking
            $._lastHarvestTime = block.timestamp;
            $._totalFeesCollected += protocolFee;
            $._totalDistributedToColEUR += distributionAmount;

            (uint256 totalYieldETH, ) = $._vaultETH.calculateTotalYield();

            emit YieldHarvestExecuted(
                block.timestamp,
                totalYieldETH,
                eurcHarvested,
                protocolFee,
                distributionAmount
            );
        }
    }

    // ============ View Functions ============

    function getHarvestingStats()
        external
        view
        returns (
            uint256 totalYieldHarvested,
            uint256 totalFeesCollected,
            uint256 totalDistributedToColEUR,
            uint256 lastHarvestTime,
            bool isPaused
        )
    {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();
        return (
            $._totalYieldHarvested,
            $._totalFeesCollected,
            $._totalDistributedToColEUR,
            $._lastHarvestTime,
            $._harvestingPaused
        );
    }

    function getConfiguration()
        external
        view
        returns (
            uint256 harvestInterval,
            uint256 minYieldThreshold,
            uint256 protocolFeeRate,
            address protocolTreasury
        )
    {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();
        return (
            $._harvestInterval,
            $._minYieldThreshold,
            $._protocolFeeRate,
            $._protocolTreasury
        );
    }

    function isAuthorizedKeeper(address keeper) external view returns (bool) {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();
        return $._authorizedKeepers[keeper];
    }

    function getCurrentYieldInfo()
        external
        view
        returns (
            uint256 totalYieldETH,
            IVaultETH.LSTBalance[] memory lstBalances,
            uint256 nextHarvestTime,
            bool canHarvestNow
        )
    {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();

        (totalYieldETH, lstBalances) = $._vaultETH.calculateTotalYield();
        nextHarvestTime = $._lastHarvestTime + $._harvestInterval;
        canHarvestNow =
            !$._harvestingPaused &&
            block.timestamp >= nextHarvestTime &&
            totalYieldETH >= $._minYieldThreshold;
    }

    // ============ Emergency Functions ============

    function emergencyWithdraw(
        address token,
        uint256 amount
    ) external restricted {
        IERC20(token).safeTransfer(msg.sender, amount);
        emit EmergencyYieldWithdrawal(token, amount);
    }

    function emergencyPause() external onlyKeeper {
        YieldHarvestingManagerStorage
            storage $ = _getYieldHarvestingManagerStorage();
        $._harvestingPaused = true;
        emit HarvestingPaused(true);
    }
}
