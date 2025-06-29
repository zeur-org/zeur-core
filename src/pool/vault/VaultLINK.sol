// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IVault} from "../../interfaces/vault/IVault.sol";
import {IStakingRouter} from "../../interfaces/router/IStakingRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract VaultLINK is
    Initializable,
    AccessManagedUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IVault
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @custom:storage-location erc7201:Zeur.storage.VaultLINK
    struct VaultLINKStorage {
        IERC20 _link; // Underlying token
        IStakingRouter _currentStakingRouter;
        IStakingRouter _currentUnstakingRouter;
        EnumerableSet.AddressSet _stakingRouters;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.VaultLINK")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VaultLINKStorageLocation =
        0xf1bb71ad1b66af00c66d93c929e3bf8ea5561f985cd82896f24f2b9c63a7fd00;

    function _getVaultLINKStorage()
        private
        pure
        returns (VaultLINKStorage storage $)
    {
        assembly {
            $.slot := VaultLINKStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        address link
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        VaultLINKStorage storage $ = _getVaultLINKStorage();
        $._link = IERC20(link);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function addStakingRouter(address router) external restricted {
        VaultLINKStorage storage $ = _getVaultLINKStorage();

        if ($._stakingRouters.contains(router))
            revert Vault_StakingRouterAlreadyAdded(router);

        $._stakingRouters.add(router);
        emit StakingRouterAdded(router);
    }

    function removeStakingRouter(address router) external restricted {
        VaultLINKStorage storage $ = _getVaultLINKStorage();

        if (!$._stakingRouters.contains(router))
            revert Vault_StakingRouterAlreadyRemoved(router);

        $._stakingRouters.remove(router);
        emit StakingRouterRemoved(router);
    }

    function updateCurrentStakingRouter(address router) external restricted {
        VaultLINKStorage storage $ = _getVaultLINKStorage();
        if (!$._stakingRouters.contains(router))
            revert Vault_InvalidStakingRouter(router);

        $._currentStakingRouter = IStakingRouter(router);
        emit CurrentStakingRouterUpdated(router);
    }

    function updateCurrentUnstakingRouter(address router) external restricted {
        VaultLINKStorage storage $ = _getVaultLINKStorage();

        if (!$._stakingRouters.contains(router))
            revert Vault_InvalidStakingRouter(router);

        $._currentUnstakingRouter = IStakingRouter(router);
        emit CurrentUnstakingRouterUpdated(router);
    }

    function getCurrentStakingRouter() external view returns (address) {
        VaultLINKStorage storage $ = _getVaultLINKStorage();
        return address($._currentStakingRouter);
    }

    function getCurrentUnstakingRouter() external view returns (address) {
        VaultLINKStorage storage $ = _getVaultLINKStorage();
        return address($._currentUnstakingRouter);
    }

    function getStakingRouters() external view returns (address[] memory) {
        VaultLINKStorage storage $ = _getVaultLINKStorage();
        return $._stakingRouters.values();
    }

    function lockCollateral(
        address from,
        uint256 amount
    ) external payable restricted {
        VaultLINKStorage storage $ = _getVaultLINKStorage();

        IStakingRouter stakingRouter = $._currentStakingRouter;
        $._link.forceApprove(address(stakingRouter), amount);
        stakingRouter.stake(address(this), amount);
    }

    function unlockCollateral(address to, uint256 amount) external restricted {
        VaultLINKStorage storage $ = _getVaultLINKStorage();

        IStakingRouter unstakingRouter = $._currentUnstakingRouter;
        IERC20(unstakingRouter.getStakedToken()).forceApprove(
            address(unstakingRouter),
            amount
        );
        unstakingRouter.unstake(to, amount);
    }

    function harvestYield(
        address router
    ) external restricted returns (address, uint256) {
        VaultLINKStorage storage $ = _getVaultLINKStorage();
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

        // Transfer lstToken back to ProtocolVaultManager
        IERC20(lstToken).safeTransfer(msg.sender, yieldAmount);

        emit YieldHarvested(address(router), lstToken, yieldAmount);

        return (lstToken, yieldAmount);
    }
}
