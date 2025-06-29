// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ETH_TO_WEI} from "../../helpers/Constants.sol";
import {IVault} from "../../interfaces/vault/IVault.sol";
import {IStakingRouter} from "../../interfaces/router/IStakingRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract VaultAVAX is
    Initializable,
    AccessManagedUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IVault
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @custom:storage-location erc7201:Zeur.storage.VaultAVAX
    struct VaultAVAXStorage {
        IStakingRouter _currentStakingRouter;
        IStakingRouter _currentUnstakingRouter;
        EnumerableSet.AddressSet _stakingRouters;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.VaultAVAX")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VaultAVAXStorageLocation =
        0xc8fef9b2f9c465bcc3bf2eea0eddb9d97c6d1cd8ea543e81e414ca8f5c82de00;

    function _getVaultAVAXStorage()
        private
        pure
        returns (VaultAVAXStorage storage $)
    {
        assembly {
            $.slot := VaultAVAXStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAuthority) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function addStakingRouter(address router) external restricted {
        VaultAVAXStorage storage $ = _getVaultAVAXStorage();

        if ($._stakingRouters.contains(router))
            revert Vault_StakingRouterAlreadyAdded(router);

        $._stakingRouters.add(router);
        emit StakingRouterAdded(router);
    }

    function removeStakingRouter(address router) external restricted {
        VaultAVAXStorage storage $ = _getVaultAVAXStorage();

        if (!$._stakingRouters.contains(router))
            revert Vault_StakingRouterAlreadyRemoved(router);

        $._stakingRouters.remove(router);
        emit StakingRouterRemoved(router);
    }

    function updateCurrentStakingRouter(address router) external restricted {
        VaultAVAXStorage storage $ = _getVaultAVAXStorage();
        if (!$._stakingRouters.contains(router))
            revert Vault_InvalidStakingRouter(router);

        $._currentStakingRouter = IStakingRouter(router);
        emit CurrentStakingRouterUpdated(router);
    }

    function updateCurrentUnstakingRouter(address router) external restricted {
        VaultAVAXStorage storage $ = _getVaultAVAXStorage();

        if (!$._stakingRouters.contains(router))
            revert Vault_InvalidStakingRouter(router);

        $._currentUnstakingRouter = IStakingRouter(router);
        emit CurrentUnstakingRouterUpdated(router);
    }

    function getCurrentStakingRouter() external view returns (address) {
        VaultAVAXStorage storage $ = _getVaultAVAXStorage();
        return address($._currentStakingRouter);
    }

    function getCurrentUnstakingRouter() external view returns (address) {
        VaultAVAXStorage storage $ = _getVaultAVAXStorage();
        return address($._currentUnstakingRouter);
    }

    function getStakingRouters() external view returns (address[] memory) {
        VaultAVAXStorage storage $ = _getVaultAVAXStorage();
        return $._stakingRouters.values();
    }

    function lockCollateral(
        address from,
        uint256 amount
    ) external payable restricted {
        if (msg.value != amount) revert Vault_InvalidAmount();

        VaultAVAXStorage storage $ = _getVaultAVAXStorage();

        // Stake AVAX through StakingRouter, transfer the LST token back to the Vault
        IStakingRouter stakingRouter = $._currentStakingRouter;
        stakingRouter.stake{value: amount}(address(this), amount); // stake AVAX on behalf of the Vault
    }

    function unlockCollateral(address to, uint256 amount) external restricted {
        VaultAVAXStorage storage $ = _getVaultAVAXStorage();

        IStakingRouter unstakingRouter = $._currentUnstakingRouter;

        (address lstToken, uint256 exchangeRate) = unstakingRouter
            .getStakedTokenAndExchangeRate();

        uint256 lstAmount = (amount * ETH_TO_WEI) / exchangeRate;

        // Approve the StakingRouter to use LST token
        // Unstake using the user's address as "to"
        IERC20(lstToken).forceApprove(address(unstakingRouter), lstAmount);
        unstakingRouter.unstake(to, lstAmount);
    }

    function harvestYield(
        address router
    ) external restricted returns (address, uint256) {
        VaultAVAXStorage storage $ = _getVaultAVAXStorage();
        if (!$._stakingRouters.contains(router))
            revert Vault_InvalidStakingRouter(router);

        (address lstToken, uint256 exchangeRate) = IStakingRouter(router)
            .getStakedTokenAndExchangeRate();
        uint256 underlyingAmount = IStakingRouter(router)
            .getTotalStakedUnderlying();

        uint256 lstAmount = IERC20(lstToken).balanceOf(address(this));
        uint256 yieldAmount = (lstAmount * exchangeRate) /
            1e18 -
            underlyingAmount;

        if (yieldAmount == 0) return (lstToken, 0);

        // Only ProtocolManager can call this function
        // Transfer LST to ProtocolVaultManager
        IERC20(lstToken).safeTransfer(msg.sender, yieldAmount);

        return (lstToken, yieldAmount);
    }
}
