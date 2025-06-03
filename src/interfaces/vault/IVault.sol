// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IVault
/// @notice Interface for the ETH vault
/// @dev This interface defines the functions for the ETH vault
interface IVault {
    /// ─── Registry & Configuration ─────────────────────────

    /// @notice Register a new staking router for an asset
    /// @param router  Address of the StakingRouter
    function addStakingRouter(address router) external;

    /// @notice Remove an existing staking router
    /// @param router  Address of the StakingRouter
    function removeStakingRouter(address router) external;

    /// @notice Update the current staking router
    /// @param router  Address of the StakingRouter
    function updateCurrentStakingRouter(address router) external;

    /// @notice Update the current unstaking router
    /// @param router  Address of the UnstakingRouter
    function updateCurrentUnstakingRouter(address router) external;

    /// @notice Get the current unstaking router
    function getCurrentUnstakingRouter() external view returns (address);

    /// @notice Get the current staking router
    function getCurrentStakingRouter() external view returns (address);

    /// ─── Protocol Selection ───────────────────────────────

    /// @notice Return the router to use given current conditions
    /// @dev Could be on‐chain price‐based, round‐robin, or weight‐based
    function getCurrentRouter() external view returns (address);

    /// @notice List all registered routers
    function getStakingRouters() external view returns (address[] memory);

    /// ─── Collateral Routing ───────────────────────────────

    /// @notice Stakes user ETH into the selected LST protocol
    /// @param from    The LendingPool (msg.sender)
    /// @param amount  Amount of ETH to stake
    function lockCollateral(address from, uint256 amount) external payable;

    /// @notice Unstakes LSTs back into ETH for user withdrawal
    /// @param to      The LendingPool (msg.sender)
    /// @param amount  Amount of ETH equivalent to unstake
    function unlockCollateral(address to, uint256 amount) external;

    /// ─── Rebalancing & Emergency ─────────────────────────

    /// @notice Force a rebalance across routers (called by Keeper or Manager)
    function rebalance() external;

    /// @notice Emergency unstake from all routers back to vault
    function emergencyUnstakeAll() external;
}
