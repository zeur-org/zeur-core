// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IProtocolVaultManager {
    error ProtocolVaultManager__NotDebtAsset(address asset);

    error ProtocolVaultManager__HarvestYieldFailed(
        address router,
        address debtAsset,
        address swapRouter
    );

    event YieldDistributed(
        address indexed router,
        address indexed debtAsset,
        address indexed colToken,
        uint256 debtReceived
    );

    event YieldHarvested(
        address indexed fromVault,
        address indexed router,
        address indexed debtAsset,
        uint256 debtReceived
    );

    event PositionRebalanced(
        address indexed fromVault,
        address indexed fromRouter,
        address indexed toRouter,
        uint256 amount
    );

    /// @notice Distribute yield to the protocol treasury
    /// @dev Callable from Chainlink Automation Keper
    /// @param asset The asset to distribute yield from
    /// @param amount The amount of yield to distribute
    function distributeYield(address asset, uint256 amount) external;

    /// @notice Harvest yield from `router` and swap to `debtAsset`
    /// @dev Callable from Chainlink Automation Keper
    /// @param fromVault The vault contract holding the LST tokens
    /// @param router The router to harvest yield from (e.g., Lido, RocketPool)
    /// @param debtAsset The asset to swap the yield to (e.g., EURC)
    /// @param swapRouter The router to swap the yield to (e.g., Uniswap)
    function harvestYield(
        address fromVault,
        address router,
        address debtAsset,
        address swapRouter
    ) external returns (uint256 debtReceived);

    /// @notice Unstake `amount` from `fromRouter` and immediately stake into `toRouter`
    /// @dev Callable from ElizaOS
    /// @param vault The vault contract holding the LST tokens
    /// @param fromRouter The router to unstake from (e.g., Lido, RocketPool)
    /// @param toRouter   The router to stake into
    /// @param amount     Amount of LST (or ETH) to move
    function rebalance(
        address vault,
        address fromRouter,
        address toRouter,
        uint256 amount
    ) external;
}
