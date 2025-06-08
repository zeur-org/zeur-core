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
        ILido _stETH; // LST token
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
        address stETH,
        address withdrawalQueueERC721
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        StakingRouterETHLidoStorage
            storage $ = _getStakingRouterETHLidoStorage();

        $._stETH = ILido(stETH);
        $._withdrawalQueueERC721 = IWithdrawalQueueERC721(
            withdrawalQueueERC721
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function stake(address from, uint256 amount) external payable restricted {
        StakingRouterETHLidoStorage
            storage $ = _getStakingRouterETHLidoStorage();

        uint256 stETHAmount = $._stETH.submit{value: amount}(from);

        IERC20(address($._stETH)).safeTransfer(from, stETHAmount);

        $._totalStakedUnderlying += amount;
    }

    function unstake(address to, uint256 amount) external restricted {
        StakingRouterETHLidoStorage
            storage $ = _getStakingRouterETHLidoStorage();

        IERC20 stETH = IERC20(address($._stETH));

        stETH.safeTransferFrom(msg.sender, address(this), amount);
        stETH.forceApprove(address($._withdrawalQueueERC721), amount);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // Send withdrawal request
        uint256[] memory requestIds = $
            ._withdrawalQueueERC721
            .requestWithdrawals(amounts, address(this));

        // TODO: Store this requestId to claimWithdrawal later

        $._totalStakedUnderlying -= amount;
    }

    function claimUnstake(uint256 requestId) external restricted {
        StakingRouterETHLidoStorage
            storage $ = _getStakingRouterETHLidoStorage();

        $._withdrawalQueueERC721.claimWithdrawal(requestId);
    }

    function getUnderlyingToken() external pure returns (address) {
        return ETH_ADDRESS;
    }

    function getStakedToken() external view returns (address) {
        StakingRouterETHLidoStorage
            storage $ = _getStakingRouterETHLidoStorage();

        return address($._stETH);
    }

    function getTotalStakedUnderlying() external view returns (uint256) {
        StakingRouterETHLidoStorage
            storage $ = _getStakingRouterETHLidoStorage();

        return $._totalStakedUnderlying;
    }

    function getStakedTokenAndExchangeRate()
        external
        view
        returns (address, uint256)
    {
        StakingRouterETHLidoStorage
            storage $ = _getStakingRouterETHLidoStorage();

        return (address($._stETH), 1e18); // 1 ETH = 1 stETH
    }

    function getExchangeRate() external pure returns (uint256) {
        return 1e18; // 1 ETH = 1 stETH
    }
}
