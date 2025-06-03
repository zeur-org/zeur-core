// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IStakingRouter} from "../interfaces/router/IStakingRouter.sol";
import {ETH_ADDRESS} from "../helpers/Constants.sol";
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

    function stake(uint256 amount, address receiver) external override {}

    function unstake(uint256 amount, address receiver) external override {}

    function claimRewards() external override {}

    function getUnderlyingToken() external view override returns (address) {}

    function getStakedToken() external view override returns (address) {}

    function getTotalUnderlying() external view override returns (uint256) {}

    function getTotalStaked() external view override returns (uint256) {}

    function getYieldCurrent() external view override returns (uint256) {}

    function getYieldPreview(
        uint256 amount
    ) external view override returns (uint256) {}
}
