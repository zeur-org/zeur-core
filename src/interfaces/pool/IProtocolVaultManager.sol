// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IProtocolVaultManager
 * @notice Interface for managing protocol vaults, yield distribution, and staking operations
 * @dev This interface handles the management of liquid staking tokens (LSTs), yield harvesting,
 *      and rebalancing operations across different staking protocols like Lido, RocketPool, etc.
 *      It's designed to work with Chainlink Automation and ElizaOS for automated operations.
 */
interface IProtocolVaultManager {
    /**
     * @notice Thrown when an asset is not recognized as a debt asset
     * @param asset The address of the asset that is not a debt asset
     */
    error ProtocolVaultManager__NotDebtAsset(address asset);

    /**
     * @notice Thrown when yield harvesting operation fails
     * @param router The router address where harvesting failed
     * @param debtAsset The debt asset that was being targeted for swap
     * @param swapRouter The swap router that failed during the operation
     */
    error ProtocolVaultManager__HarvestYieldFailed(
        address router,
        address debtAsset,
        address swapRouter
    );

    /**
     * @notice Emitted when yield is distributed to the protocol treasury
     * @param router The router from which yield was distributed
     * @param debtAsset The debt asset that received the yield
     * @param colToken The collateral token associated with the yield
     * @param debtReceived The amount of debt tokens received from yield distribution
     */
    event YieldDistributed(
        address indexed router,
        address indexed debtAsset,
        address indexed colToken,
        uint256 debtReceived
    );

    /**
     * @notice Emitted when yield is harvested from a staking protocol
     * @param fromVault The vault contract from which yield was harvested
     * @param router The staking router (e.g., Lido, RocketPool) from which yield was harvested
     * @param debtAsset The debt asset that the yield was swapped to
     * @param debtReceived The amount of debt tokens received from the harvest
     */
    event YieldHarvested(
        address indexed fromVault,
        address indexed router,
        address indexed debtAsset,
        uint256 debtReceived
    );

    /**
     * @notice Emitted when LST positions are rebalanced between different staking protocols
     * @param fromVault The vault contract holding the LST tokens
     * @param fromRouter The source staking router from which tokens were unstaked
     * @param toRouter The destination staking router to which tokens were staked
     * @param amount The amount of tokens (LST or ETH) that were rebalanced
     */
    event PositionRebalanced(
        address indexed fromVault,
        address indexed fromRouter,
        address indexed toRouter,
        uint256 amount
    );

    /**
     * @notice Distribute yield to the protocol treasury
     * @dev This function is designed to be called by Chainlink Automation Keepers
     *      to automatically distribute accumulated yield to the protocol treasury.
     *      The yield is typically generated from staking rewards on LSTs.
     * @param asset The asset from which yield should be distributed
     * @param amount The amount of yield to distribute to the treasury
     */
    function distributeYield(address asset, uint256 amount) external;

    /**
     * @notice Harvest yield from a staking protocol and swap to a debt asset
     * @dev This function is designed to be called by Chainlink Automation Keepers
     *      to automatically harvest staking rewards and swap them to the target debt asset.
     *      The process involves claiming rewards from the staking protocol and using a DEX
     *      to swap the rewards to the desired debt asset (e.g., EURC).
     * @param fromVault The vault contract that holds the LST tokens
     * @param router The staking router to harvest yield from (e.g., Lido, RocketPool)
     * @param debtAsset The target debt asset to swap the harvested yield to (e.g., EURC)
     * @param swapRouter The DEX router to use for swapping (e.g., Uniswap)
     * @return debtReceived The amount of debt tokens received from the harvest and swap operation
     */
    function harvestYield(
        address fromVault,
        address router,
        address debtAsset,
        address swapRouter
    ) external returns (uint256 debtReceived);

    /**
     * @notice Rebalance LST positions between different staking protocols
     * @dev This function allows for rebalancing of liquid staking positions by unstaking
     *      from one protocol and immediately staking into another. This is useful for
     *      optimizing yield or managing risk across different staking protocols.
     *      This function is designed to be called by ElizaOS for intelligent rebalancing.
     * @param vault The vault contract that holds the LST tokens
     * @param fromRouter The source staking router to unstake from (e.g., Lido, RocketPool)
     * @param toRouter The destination staking router to stake into
     * @param amount The amount of LST tokens or ETH to move between protocols
     */
    function rebalance(
        address vault,
        address fromRouter,
        address toRouter,
        uint256 amount
    ) external;
}
