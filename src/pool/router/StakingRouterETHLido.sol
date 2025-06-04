// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ILido} from "../../interfaces/lst/lido/ILido.sol";
import {IWithdrawalQueueERC721} from "../../interfaces/lst/lido/IWithdrawalQueueERC721.sol";
import {IStakingRouter} from "../../interfaces/router/IStakingRouter.sol";
import {ETH_ADDRESS} from "../../helpers/Constants.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract StakingRouterETHLido is
    Initializable,
    AccessManagedUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IStakingRouter
{
    using SafeERC20 for IERC20;

    struct StakingRouterETHLidoStorage {
        uint256 _totalStakedUnderlying;
        ILido _lido;
        IWithdrawalQueueERC721 _withdrawalQueueERC721;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.StakingRouterETHLido")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant StakingRouterETHLidoStorageLocation =
        0x4919a4906d22854e05d6bedefd40c3e02eba2bf042b0fbf851a3d8cafc07ca00;

    function _getStakingRouterETHLidoStorage()
        private
        pure
        returns (StakingRouterETHLidoStorage storage $)
    {
        assembly {
            $.slot := StakingRouterETHLidoStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        address lido,
        address withdrawalQueueERC721
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        StakingRouterETHLidoStorage
            storage $ = _getStakingRouterETHLidoStorage();

        $._lido = ILido(lido);
        $._withdrawalQueueERC721 = IWithdrawalQueueERC721(
            withdrawalQueueERC721
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function stake(
        uint256 amount,
        address receiver
    ) external payable restricted {
        StakingRouterETHLidoStorage
            storage $ = _getStakingRouterETHLidoStorage();

        uint256 stETHAmount = $._lido.submit{value: amount}(receiver);

        IERC20(address($._lido)).safeTransfer(receiver, stETHAmount);

        $._totalStakedUnderlying += amount;
    }

    function unstake(uint256 amount, address receiver) external restricted {
        StakingRouterETHLidoStorage
            storage $ = _getStakingRouterETHLidoStorage();

        IERC20 stETH = IERC20(address($._lido));

        stETH.safeTransferFrom(msg.sender, address(this), amount);
        stETH.approve(address($._withdrawalQueueERC721), amount);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        $._withdrawalQueueERC721.requestWithdrawals(amounts, receiver);

        $._totalStakedUnderlying -= amount;
    }

    function getUnderlyingToken() external pure returns (address) {
        return ETH_ADDRESS;
    }

    function getStakedToken() external view returns (address) {
        StakingRouterETHLidoStorage
            storage $ = _getStakingRouterETHLidoStorage();

        return address($._lido);
    }

    function getTotalStakedUnderlying() external view returns (uint256) {
        StakingRouterETHLidoStorage
            storage $ = _getStakingRouterETHLidoStorage();

        return $._totalStakedUnderlying;
    }
}
