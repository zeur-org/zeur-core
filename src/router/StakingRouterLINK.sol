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

contract StakingRouterLINK is
    Initializable,
    AccessManagedUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IStakingRouter
{
    using SafeERC20 for IERC20;

    struct StakingRouterLINKStorage {
        IERC20 _underlyingToken;
        IERC20 _stakedToken;
        IERC20 _vaultLink;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.StakingRouterLINK")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant StakingRouterLINKStorageLocation =
        0x3b4b361881829a1703fbe4d2365da6a97131f1374cd00d1ab5afaa92072ee900;

    function _getStakingRouterLINKStorage()
        private
        pure
        returns (StakingRouterLINKStorage storage $)
    {
        assembly {
            $.slot := StakingRouterLINKStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        address linkToken,
        address stLinkToken,
        address vaultLink
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        StakingRouterLINKStorage storage $ = _getStakingRouterLINKStorage();

        $._underlyingToken = IERC20(linkToken);
        $._stakedToken = IERC20(stLinkToken);
        $._vaultLink = IERC20(vaultLink);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function stake(uint256 amount, address receiver) external payable {
        StakingRouterLINKStorage storage $ = _getStakingRouterLINKStorage();
        $._underlyingToken.transferFrom(msg.sender, address(this), amount);

        $._stakedToken.approve(address(this), amount);
        uint256 sharesAmount = $._stakedToken.getSharesByStake(amount);

        // TODO: Stake
    }

    function unstake(uint256 amount, address receiver) external {}

    function getUnderlyingToken() external view returns (address) {
        StakingRouterLINKStorage storage $ = _getStakingRouterLINKStorage();
        return address($._underlyingToken);
    }

    function getStakedToken() external view returns (address) {
        StakingRouterLINKStorage storage $ = _getStakingRouterLINKStorage();
        return address($._stakedToken);
    }

    function getTotalStakedUnderlying() external view returns (uint256) {}
}
