// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IStakingRouter} from "../../interfaces/router/IStakingRouter.sol";
import {ETH_ADDRESS} from "../../helpers/Constants.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract StakingRouterETHEtherfi is
    Initializable,
    AccessManagedUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IStakingRouter
{
    using SafeERC20 for IERC20;

    struct StakingRouterETHEtherfiStorage {
        uint256 _totalStakedUnderlying;
        IERC20 _eETH; // LST token
        IERC20 _underlyingToken; // Underlying token
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.StakingRouterETHEtherfi")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant StakingRouterETHEtherfiStorageLocation =
        0x4919a4906d22854e05d6bedefd40c3e02eba2bf042b0fbf851a3d8cafc07ca00;

    function _getStakingRouterETHEtherfiStorage()
        private
        pure
        returns (StakingRouterETHEtherfiStorage storage $)
    {
        assembly {
            $.slot := StakingRouterETHEtherfiStorageLocation
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

    // transferFrom(vault, router, amount)
    // => approve(lstPool, amount)
    // => lstPool.deposit(amount)
    // => lst.transfer(vault, lstAmount)
    function stake(
        uint256 amount,
        address receiver
    ) external payable restricted {
        uint256 amount = msg.value;

        if (amount == 0) revert StakingRouter_InvalidAmount();
        StakingRouterETHEtherfiStorage
            storage $ = _getStakingRouterETHEtherfiStorage();
    }

    function unstake(uint256 amount, address receiver) external restricted {}

    function getUnderlyingToken() external pure returns (address) {
        return ETH_ADDRESS;
    }

    function getStakedToken() external view returns (address) {
        StakingRouterETHEtherfiStorage
            storage $ = _getStakingRouterETHEtherfiStorage();

        return address($._eETH);
    }

    function getTotalStakedUnderlying() external view returns (uint256) {
        StakingRouterETHEtherfiStorage
            storage $ = _getStakingRouterETHEtherfiStorage();

        return $._totalStakedUnderlying;
    }
}
