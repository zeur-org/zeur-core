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

    struct StakingRouterETHMorphoStorage {
        uint256 _totalStakedUnderlying;
        IMorphoVault _morphoVault;
        IWETH _weth;
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
        address morphoVault,
        address weth
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        StakingRouterETHMorphoStorage
            storage $ = _getStakingRouterETHMorphoStorage();

        $._morphoVault = IMorphoVault(morphoVault);
        $._weth = IWETH(weth);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function stake(
        uint256 amount,
        address receiver
    ) external payable restricted {
        StakingRouterETHMorphoStorage
            storage $ = _getStakingRouterETHMorphoStorage();

        // Wrap ETH into WETH
        $._weth.deposit{value: amount}();

        // Deposit WETH into Morpho Vault
        uint256 shares = $._morphoVault.deposit(amount, receiver);
        $._totalStakedUnderlying += amount;

        // Transfer shares back to Zeur VaultETH contract
        $._morphoVault.transfer(receiver, shares);
    }

    function unstake(uint256 amount, address receiver) external restricted {
        StakingRouterETHMorphoStorage
            storage $ = _getStakingRouterETHMorphoStorage();

        $._morphoVault.transferFrom(msg.sender, address(this), amount);

        // Withdraw WETH from Morpho Vault
        $._morphoVault.withdraw(amount, receiver, address(this));

        // Unwrap WETH into ETH
        $._weth.withdraw(amount);
        $._totalStakedUnderlying -= amount;

        // Transfer ETH to Zeur VaultETH contract
        (bool success, ) = payable(receiver).call{value: amount}("");
        if (!success) revert StakingRouter_FailedToTransfer();
    }

    function getUnderlyingToken() external view returns (address) {
        StakingRouterETHMorphoStorage
            storage $ = _getStakingRouterETHMorphoStorage();

        return address($._weth);
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
}
