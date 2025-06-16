// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ETHER_TO_WEI} from "../../helpers/Constants.sol";
import {IVaultETH} from "../../interfaces/vault/IVaultETH.sol";
import {IStakingRouter} from "../../interfaces/router/IStakingRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract VaultETH is
    Initializable,
    AccessManagedUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IVaultETH
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct VaultETHStorage {
        IStakingRouter _currentStakingRouter;
        IStakingRouter _currentUnstakingRouter;
        EnumerableSet.AddressSet _stakingRouters;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.VaultETH")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VaultETHStorageLocation =
        0xc8b310c3134a0337fa82236e9403d51a7288f6c6741d6f19762a386f4216d000;

    function _getVaultETHStorage()
        private
        pure
        returns (VaultETHStorage storage $)
    {
        assembly {
            $.slot := VaultETHStorageLocation
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

    function addStakingRouter(address router) external restricted {
        VaultETHStorage storage $ = _getVaultETHStorage();

        if ($._stakingRouters.contains(router))
            revert Vault_StakingRouterAlreadyAdded(router);

        $._stakingRouters.add(router);
        emit StakingRouterAdded(router);
    }

    function removeStakingRouter(address router) external restricted {
        VaultETHStorage storage $ = _getVaultETHStorage();

        if (!$._stakingRouters.contains(router))
            revert Vault_StakingRouterAlreadyRemoved(router);

        $._stakingRouters.remove(router);
        emit StakingRouterRemoved(router);
    }

    function updateCurrentStakingRouter(address router) external restricted {
        VaultETHStorage storage $ = _getVaultETHStorage();
        if (!$._stakingRouters.contains(router))
            revert Vault_InvalidStakingRouter(router);

        $._currentStakingRouter = IStakingRouter(router);
        emit CurrentStakingRouterUpdated(router);
    }

    function updateCurrentUnstakingRouter(address router) external restricted {
        VaultETHStorage storage $ = _getVaultETHStorage();

        if (!$._stakingRouters.contains(router))
            revert Vault_InvalidStakingRouter(router);

        $._currentUnstakingRouter = IStakingRouter(router);
        emit CurrentUnstakingRouterUpdated(router);
    }

    function getCurrentStakingRouter() external view returns (address) {
        VaultETHStorage storage $ = _getVaultETHStorage();
        return address($._currentStakingRouter);
    }

    function getCurrentUnstakingRouter() external view returns (address) {
        VaultETHStorage storage $ = _getVaultETHStorage();
        return address($._currentUnstakingRouter);
    }

    function getStakingRouters() external view returns (address[] memory) {
        VaultETHStorage storage $ = _getVaultETHStorage();
        return $._stakingRouters.values();
    }

    function lockCollateral(
        address from,
        uint256 amount
    ) external payable restricted {
        if (msg.value != amount) revert Vault_InvalidAmount();

        VaultETHStorage storage $ = _getVaultETHStorage();

        // Stake ETH through StakingRouter, transfer the LST token back to the Vault
        IStakingRouter stakingRouter = $._currentStakingRouter;
        stakingRouter.stake{value: amount}(address(this), amount); // stake ETH on behalf of the Vault
    }

    function unlockCollateral(address to, uint256 amount) external restricted {
        VaultETHStorage storage $ = _getVaultETHStorage();

        IStakingRouter unstakingRouter = $._currentUnstakingRouter;

        (address lstToken, uint256 exchangeRate) = unstakingRouter
            .getStakedTokenAndExchangeRate();

        uint256 lstAmount = (amount * ETHER_TO_WEI) / exchangeRate;

        // Approve the StakingRouter to use LST token
        // Unstake using the user's address as "to"
        IERC20(lstToken).forceApprove(address(unstakingRouter), lstAmount);
        unstakingRouter.unstake(to, lstAmount);
    }

    function rebalance() external restricted {}
}
