// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ETH_ADDRESS, ETHER_TO_WEI} from "../../helpers/Constants.sol";
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
    using SafeERC20 for IRETH;

    struct StakingRouterETHRocketPoolStorage {
        uint256 _totalStakedUnderlying;
        address _underlyingToken; // Underlying token
        IRETH _rETH; // LST token
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

    receive() external payable {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        address rETH,
        address depositPool,
        address protocolSettings
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        $._underlyingToken = ETH_ADDRESS;
        $._rETH = IRETH(rETH);
        $._depositPool = IRocketDepositPool(depositPool);
        $._protocolSettings = IRocketDAOProtocolSettingsDeposit(
            protocolSettings
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function stake(
        address from,
        uint256 amount
    ) external payable nonReentrant restricted {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        $._totalStakedUnderlying += amount;

        uint256 fee = (amount * $._protocolSettings.getDepositFee()) /
            ETHER_TO_WEI;
        uint256 ethDepositNet = amount - fee;
        uint256 rEthAmount = $._rETH.getRethValue(ethDepositNet);

        // Deposit ETH into the deposit pool
        $._depositPool.deposit{value: amount}();

        // Mint rETH to the receiver
        $._rETH.safeTransfer(from, rEthAmount);
    }

    function unstake(
        address to,
        uint256 amount
    ) external nonReentrant restricted {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        $._totalStakedUnderlying -= amount;

        $._rETH.safeTransferFrom(msg.sender, address(this), amount);
        $._rETH.burn(amount);

        // Transfer back ETH to final receiver
        uint256 ethAmount = $._rETH.getEthValue(amount);
        (bool success, ) = payable(to).call{value: ethAmount}("");
        if (!success) revert StakingRouter_FailedToTransfer();
    }

    function getExchangeRate() external view override returns (uint256) {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        return $._rETH.getExchangeRate();
    }

    function getStakedToken() external view returns (address) {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        return address($._rETH);
    }

    function getStakedTokenAndExchangeRate()
        external
        view
        returns (address, uint256)
    {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        IRETH rETH = $._rETH;

        return (address(rETH), rETH.getExchangeRate());
    }

    function getUnderlyingToken() external view returns (address) {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        return $._underlyingToken;
    }

    function getTotalStakedUnderlying() external view returns (uint256) {
        StakingRouterETHRocketPoolStorage
            storage $ = _getStakingRouterETHRocketPoolStorage();

        return $._totalStakedUnderlying;
    }
}
