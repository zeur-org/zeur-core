// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ETH_ADDRESS} from "../../helpers/Constants.sol";
import {IStakingRouter} from "../../interfaces/router/IStakingRouter.sol";
import {IPriorityPool} from "../../interfaces/lst/stake-link/IPriorityPool.sol";
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
        uint256 _totalStakedUnderlying;
        IERC20 _link; // Underlying token
        IERC20 _stLINK; // LST token
        IPriorityPool _linkPriorityPool;
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
        address linkPriorityPool
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        StakingRouterLINKStorage storage $ = _getStakingRouterLINKStorage();

        $._link = IERC20(linkToken);
        $._stLINK = IERC20(stLinkToken);
        $._linkPriorityPool = IPriorityPool(linkPriorityPool);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function stake(address from, uint256 amount) external payable restricted {
        StakingRouterLINKStorage storage $ = _getStakingRouterLINKStorage();

        // Update the total staked underlying
        $._totalStakedUnderlying += amount;

        // Transfer LINK from the Vault to the router
        $._link.safeTransferFrom(msg.sender, address(this), amount);

        // Approve the stake.link priority pool to spend the LINK
        $._link.forceApprove(address($._linkPriorityPool), amount);

        // Stake the LINK in the priority pool
        bytes[] memory data = new bytes[](0);
        $._linkPriorityPool.deposit(amount, false, data);

        // Transfer back stLINK to VaultLINK
        $._stLINK.safeTransfer(from, amount);
    }

    function unstake(address to, uint256 amount) external restricted {
        StakingRouterLINKStorage storage $ = _getStakingRouterLINKStorage();
        $._totalStakedUnderlying -= amount;

        // Transfer stLINK from the router to the Vault
        $._stLINK.safeTransferFrom(msg.sender, address(this), amount);

        // Withdraw the LINK from the priority pool
        $._linkPriorityPool.withdraw(
            amount, // amount to withdraw
            0, // amount
            0, // shares amount
            new bytes32[](0), // merkle proof
            false, // should unqueue
            false, // should queue withdrawal
            new bytes[](0) // data
        );

        // Transfer the LINK from the router to the Vault
        $._link.safeTransfer(to, amount);
    }

    function getExchangeRate() external pure returns (uint256) {
        return 1e18; // 1 LINK = 1 stLINK
    }

    function getStakedToken() external view returns (address) {
        StakingRouterLINKStorage storage $ = _getStakingRouterLINKStorage();
        return address($._stLINK);
    }

    function getStakedTokenAndExchangeRate()
        external
        view
        returns (address, uint256)
    {
        StakingRouterLINKStorage storage $ = _getStakingRouterLINKStorage();

        return (address($._stLINK), 1e18); // 1 LINK = 1 stLINK
    }

    function getUnderlyingToken() external view returns (address) {
        StakingRouterLINKStorage storage $ = _getStakingRouterLINKStorage();
        return address($._link);
    }

    function getTotalStakedUnderlying() external view returns (uint256) {
        StakingRouterLINKStorage storage $ = _getStakingRouterLINKStorage();
        return $._totalStakedUnderlying;
    }
}
