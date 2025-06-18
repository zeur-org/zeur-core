// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IStakingRouter} from "../../interfaces/router/IStakingRouter.sol";
import {ETH_ADDRESS, WETH_ADDRESS} from "../../helpers/Constants.sol";
import {IWETH} from "../../interfaces/lst/wrap/IWETH.sol";
import {IMorphoVault} from "../../interfaces/lst/morpho/IMorphoVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract StakingRouterETHMorpho is
    Initializable,
    AccessManagedUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IStakingRouter
{
    using SafeERC20 for IERC20;
    using SafeERC20 for IMorphoVault;

    struct StakingRouterETHMorphoStorage {
        uint256 _totalStakedUnderlying;
        IWETH _wETH; // LST token
        IMorphoVault _morphoVault; // Underlying token
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.StakingRouterETHMorpho")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant StakingRouterETHMorphoStorageLocation =
        0x4919a4906d22854e05d6bedefd40c3e02eba2bf042b0fbf851a3d8cafc07ca00;

    function _getStakingRouterETHMorphoStorage()
        private
        pure
        returns (StakingRouterETHMorphoStorage storage $)
    {
        assembly {
            $.slot := StakingRouterETHMorphoStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        address wETH,
        address morphoVault
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        StakingRouterETHMorphoStorage
            storage $ = _getStakingRouterETHMorphoStorage();

        $._wETH = IWETH(wETH);
        $._morphoVault = IMorphoVault(morphoVault);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function stake(address from, uint256 amount) external payable restricted {
        StakingRouterETHMorphoStorage
            storage $ = _getStakingRouterETHMorphoStorage();
        $._totalStakedUnderlying += amount;

        // Wrap ETH into WETH
        $._wETH.deposit{value: amount}();

        // Approve and deposit WETH into Morpho Vault
        $._wETH.approve(address($._morphoVault), amount);

        // Deposit WETH into Morpho Vault on behalf of VaultETH
        uint256 shares = $._morphoVault.deposit(amount, from);

        // No need to transfer shares back to Zeur VaultETH contract
        // $._morphoVault.safeTransfer(from, shares);
    }

    function unstake(address to, uint256 amount) external restricted {
        StakingRouterETHMorphoStorage
            storage $ = _getStakingRouterETHMorphoStorage();
        $._totalStakedUnderlying -= amount;

        $._morphoVault.safeTransferFrom(msg.sender, address(this), amount);
        $._morphoVault.forceApprove(address($._morphoVault), amount);

        // Withdraw WETH from Morpho Vault
        $._morphoVault.withdraw(amount, address(this), address(this));

        // Unwrap WETH into ETH
        $._wETH.withdraw(amount);

        // Transfer ETH to Zeur VaultETH contract
        (bool success, ) = payable(to).call{value: amount}("");
        if (!success) revert StakingRouter_FailedToTransfer();
    }

    function getUnderlyingToken() external view returns (address) {
        StakingRouterETHMorphoStorage
            storage $ = _getStakingRouterETHMorphoStorage();

        return address($._wETH);
    }

    function getStakedToken() external view returns (address) {
        StakingRouterETHMorphoStorage
            storage $ = _getStakingRouterETHMorphoStorage();

        return address($._morphoVault);
    }

    function getTotalStakedUnderlying() external view returns (uint256) {
        StakingRouterETHMorphoStorage
            storage $ = _getStakingRouterETHMorphoStorage();

        return $._totalStakedUnderlying;
    }

    function getExchangeRate() external view override returns (uint256) {}

    function getStakedTokenAndExchangeRate()
        external
        view
        returns (address, uint256)
    {
        StakingRouterETHMorphoStorage
            storage $ = _getStakingRouterETHMorphoStorage();

        return (address($._morphoVault), 1e18); // TODO: exchange rate from ERC4626
    }

    receive() external payable {}
}
