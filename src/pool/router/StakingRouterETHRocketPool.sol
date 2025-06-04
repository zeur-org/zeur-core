// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ETH_ADDRESS, CALC_BASE} from "../../helpers/Constants.sol";
import {IRETH} from "../../interfaces/lst/rocket-pool/IRETH.sol";
import {IRocketDepositPool} from "../../interfaces/lst/rocket-pool/IRocketDepositPool.sol";
import {IRocketDAOProtocolSettingsDeposit} from "../../interfaces/lst/rocket-pool/IRocketDAOProtocolSettingsDeposit.sol";
import {IStakingRouter} from "../../interfaces/router/IStakingRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract StakingRouterETHRocketPool is
    Initializable,
    AccessManagedUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IStakingRouter
{
    using SafeERC20 for IERC20;

    struct StakingRouterETHRocketPoolStorage {
        uint256 _totalStakedUnderlying;
        IRETH _reth;
        IRocketDepositPool _depositPool;
        IRocketDAOProtocolSettingsDeposit _protocolSettings;
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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        address reth,
        address depositPool,
        address protocolSettings
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        $._reth = IRETH(reth);
        $._depositPool = IRocketDepositPool(depositPool);
        $._protocolSettings = IRocketDAOProtocolSettingsDeposit(
            protocolSettings
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function stake(
        uint256 amount,
        address receiver
    ) external payable nonReentrant restricted {
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

        $._totalStakedUnderlying += amount;
    }

    function unstake(
        uint256 amount,
        address receiver
    ) external nonReentrant restricted {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        $._reth.transferFrom(msg.sender, address(this), amount);
        $._reth.burn(amount);

        // Transfer back ETH to final receiver
        uint256 ethAmount = $._reth.getEthValue(amount);
        (bool success, ) = payable(receiver).call{value: ethAmount}("");
        if (!success) revert StakingRouter_FailedToTransfer();

        $._totalStakedUnderlying -= amount;
    }

    function getUnderlyingToken() external pure returns (address) {
        return ETH_ADDRESS;
    }

    function getStakedToken() external view returns (address) {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        return address($._reth);
    }

    function getTotalStakedUnderlying() external view returns (uint256) {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        return $._totalStakedUnderlying;
    }
}
