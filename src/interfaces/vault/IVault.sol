// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IVault
/// @notice Interface for the ETH vault
/// @dev This interface defines the functions for the ETH vault
interface IVault {
    error Vault_InsufficientCollateral();
    error Vault_InvalidAmount();
    error Vault_InvalidStakingRouter(address router);
    error Vault_StakingRouterAlreadyAdded(address router);
    error Vault_StakingRouterAlreadyRemoved(address router);
    error Vault_HarvestYieldFailed();

    event StakingRouterAdded(address indexed router);
    event StakingRouterRemoved(address indexed router);
    event CurrentStakingRouterUpdated(address indexed router);
    event CurrentUnstakingRouterUpdated(address indexed router);
    event YieldHarvested(
        address indexed router,
        address indexed debtAsset,
        uint256 amount
    );

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

    /// @notice List all registered routers
    function getStakingRouters() external view returns (address[] memory);

    /// @notice Stakes user ETH into the selected LST protocol
    /// @param from    The LendingPool (msg.sender)
    /// @param amount  Amount of ETH to stake
    function lockCollateral(address from, uint256 amount) external payable;

    /// @notice Unstakes LSTs back into ETH for user withdrawal
    /// @param to      The LendingPool (msg.sender)
    /// @param amount  Amount of ETH equivalent to unstake
    function unlockCollateral(address to, uint256 amount) external;

    /// @notice Force a rebalance across routers (called by Keeper or Manager)
    function rebalance() external;

    /// @notice Harvest yield from the vault
}
