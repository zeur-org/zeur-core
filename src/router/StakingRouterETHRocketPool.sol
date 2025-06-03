// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessManaged} from "openzeppelin-contracts/access/manager/AccessManaged.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import {IStakingRouter} from "../interfaces/router/IStakingRouter.sol";
import {IRETH} from "../interfaces/lst/rocket-pool/IRETH.sol";
import {IRocketDepositPool} from "../interfaces/lst/rocket-pool/IRocketDepositPool.sol";
import {IRocketDAOProtocolSettingsDeposit} from "../interfaces/lst/rocket-pool/IRocketDAOProtocolSettingsDeposit.sol";
import {IRocketStorage} from "../interfaces/lst/rocket-pool/IRocketStorage.sol";
import {ETH_ADDRESS} from "../helpers/Constants.sol";

contract StakingRouterETHRocketPool is
    AccessManaged,
    ReentrancyGuard,
    IStakingRouter
{
    using SafeERC20 for IERC20;
    uint256 constant CALC_BASE = 1e18;

    struct StakingRouterETHRocketPoolStorage {
        IRETH _reth;
        IRocketDepositPool _depositPool;
        IRocketDAOProtocolSettingsDeposit _protocolSettings;
        IRocketStorage _rocketStorage;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.StakingRouterETHRocketPool")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant StakingRouterETHRocketPoolStorageLocation =
        0x4919a4906d22854e05d6bedefd40c3e02eba2bf042b0fbf851a3d8cafc07ca00;

    function _getStakingRouterETHRocketPoolStorage()
        private
        pure
        returns (StakingRouterETHRocketPoolStorage storage $)
    {
        assembly {
            $.slot := StakingRouterETHRocketPoolStorageLocation
        }
    }

    constructor(
        address initialAuthority,
        address reth,
        address depositPool,
        address protocolSettings
    ) AccessManaged(initialAuthority) {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        $._reth = IRETH(reth);
        $._depositPool = IRocketDepositPool(depositPool);
        $._protocolSettings = IRocketDAOProtocolSettingsDeposit(
            protocolSettings
        );
    }

    function stake(
        uint256 amount,
        address receiver
    ) external override nonReentrant restricted {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        uint256 fee = (amount * $._protocolSettings.getDepositFee()) /
            CALC_BASE;
        uint256 ethDepositNet = amount - fee;
        uint256 rEthAmount = $._reth.getRethValue(ethDepositNet);

        // Deposit ETH into the deposit pool
        $._depositPool.deposit{value: ethDepositNet}();

        // Mint rETH to the receiver
        IERC20($._reth).safeTransfer(receiver, rEthAmount);
    }

    function unstake(
        uint256 amount,
        address receiver
    ) external override nonReentrant restricted {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        $._reth.transferFrom(msg.sender, address(this), amount);
        $._reth.burn(amount);

        // Transfer back ETH to final receiver
        uint256 ethAmount = $._reth.getEthValue(amount);
        (bool success, ) = payable(receiver).call{value: ethAmount}("");
        if (!success) revert StakingRouter_FailedToTransfer();
    }

    function claimRewards() external override restricted {}

    function getUnderlyingToken() external pure override returns (address) {
        return ETH_ADDRESS;
    }

    function getStakedToken() external view override returns (address) {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        return address($._reth);
    }

    function getTotalUnderlying() external view override returns (uint256) {}

    function getTotalStaked() external view override returns (uint256) {}

    function getYieldCurrent() external view override returns (uint256) {}

    function getYieldPreview(
        uint256 amount
    ) external view override returns (uint256) {}
}
