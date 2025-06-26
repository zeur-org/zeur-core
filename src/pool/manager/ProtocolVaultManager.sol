// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPool} from "../../interfaces/pool/IPool.sol";
import {IProtocolVaultManager} from "../../interfaces/pool/IProtocolVaultManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ProtocolVaultManager is
    Initializable,
    AccessManagedUpgradeable,
    UUPSUpgradeable,
    IProtocolVaultManager
{
    using SafeERC20 for IERC20;

    struct ProtocolVaultManagerStorage {
        IPool _pool;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.ProtocolVaultManager")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ProtocolVaultManagerStorageLocation =
        0x1c03345a3baecbfa5f76c98daacb964c084ba41883ee9de5881a16f46ba4f100;

    function _getProtocolVaultManagerStorage()
        private
        pure
        returns (ProtocolVaultManagerStorage storage $)
    {
        assembly {
            $.slot := ProtocolVaultManagerStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAuthority) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function distributeYield(address asset) external {
        ProtocolVaultManagerStorage
            storage $ = _getProtocolVaultManagerStorage();

        IPool.DebtConfiguration memory debtConfiguration = $
            ._pool
            .getDebtAssetConfiguration(asset);
        address colToken = debtConfiguration.colToken;

        if (colToken == address(0))
            revert ProtocolVaultManager__NotDebtAsset(asset);

        uint256 amount = IERC20(asset).balanceOf(address(this));
        IERC20(asset).safeTransfer(colToken, amount);

        emit YieldDistributed(colToken, asset, amount);
    }

    function rebalance() external {}

    function harvestYield(
        address router,
        address debtAsset
    ) external restricted returns (uint256 debtReceived) {
        VaultLINKStorage storage $ = _getVaultLINKStorage();

        IStakingRouter stakingRouter = IStakingRouter(router);
        address lstToken = stakingRouter.getStakedToken();
        uint256 underlyingAmount = stakingRouter.getTotalStakedUnderlying();
        uint256 lstAmount = IERC20(lstToken).balanceOf(address(this));
        uint256 yieldAmount = lstAmount - underlyingAmount;

        // Swap yield amount of LST to EURC, then transfer EURC to colEURC
        if (yieldAmount == 0) return 0;

        // Perform the swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: lstToken,
                tokenOut: debtAsset,
                fee: 0,
                recipient: address(this),
                deadline: block.timestamp + 300, // 5 minutes
                amountIn: yieldAmount,
                amountOutMinimum: 0, // Need slippage protection for prod
                sqrtPriceLimitX96: 0
            });

        try
            ISwapRouter($._yieldConfig.swapRouter).exactInputSingle(params)
        returns (uint256 amountOut) {
            debtReceived = amountOut;
        } catch {
            revert Vault_HarvestYieldFailed();
        }

        emit YieldHarvested(router, debtAsset, debtReceived);
    }
}
