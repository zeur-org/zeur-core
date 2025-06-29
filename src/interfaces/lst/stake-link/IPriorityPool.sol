// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.30;

/**
 * @title IPriorityPool
 * @notice Interface for StakeLink's priority pool for LINK staking
 * @dev This interface manages a priority-based staking pool where users can deposit LINK tokens
 *      and receive liquid staking derivatives. The pool uses Merkle tree distributions and
 *      queuing mechanisms to manage deposits, withdrawals, and reward distributions efficiently.
 */
interface IPriorityPool {
    /**
     * @notice Enum representing different pool operational states
     * @dev Controls the operational state of the priority pool
     */
    enum PoolStatus {
        OPEN, /// @dev Pool is open for deposits and normal operations
        DRAINING, /// @dev Pool is being drained, limited operations
        CLOSED /// @dev Pool is closed, no new operations allowed
    }

    /**
     * @notice Returns whether the pool is currently paused
     * @dev When paused, most operations are disabled for maintenance or emergency
     * @return True if the pool is paused, false otherwise
     */
    function paused() external view returns (bool);

    /**
     * @notice Returns the total deposits since the last reward distribution update
     * @dev Tracks new deposits that haven't been included in the latest distribution
     * @return The amount of tokens deposited since the last update
     */
    function depositsSinceLastUpdate() external view returns (uint256);

    /**
     * @notice Returns the current operational status of the pool
     * @dev Indicates whether the pool is open, draining, or closed
     * @return The current PoolStatus enum value
     */
    function poolStatus() external view returns (PoolStatus);

    /**
     * @notice Returns the IPFS hash of the current distribution metadata
     * @dev Contains metadata about the current reward distribution stored on IPFS
     * @return The IPFS hash as bytes32
     */
    function ipfsHash() external view returns (bytes32);

    /**
     * @notice Checks how much an account can withdraw given a distribution amount
     * @dev Calculates withdrawal eligibility based on the account's position and distribution
     * @param _account The account address to check
     * @param _distributionAmount The distribution amount to check against
     * @return The amount that can be withdrawn
     */
    function canWithdraw(
        address _account,
        uint256 _distributionAmount
    ) external view returns (uint256);

    /**
     * @notice Gets the amount of queued tokens for an account
     * @dev Returns tokens that are queued for withdrawal but not yet processed
     * @param _account The account address to query
     * @param _distributionAmount The distribution amount context
     * @return The amount of queued tokens
     */
    function getQueuedTokens(
        address _account,
        uint256 _distributionAmount
    ) external view returns (uint256);

    /**
     * @notice Gets the LSD (Liquid Staking Derivative) tokens for an account
     * @dev Calculates LSD tokens based on distribution share amount
     * @param _account The account address to query
     * @param _distributionShareAmount The share amount in the distribution
     * @return The amount of LSD tokens
     */
    function getLSDTokens(
        address _account,
        uint256 _distributionShareAmount
    ) external view returns (uint256);

    /**
     * @notice Deposits tokens into the priority pool
     * @dev Allows users to deposit LINK tokens with optional queuing and custom data
     * @param _amount The amount of tokens to deposit
     * @param _shouldQueue Whether to queue the deposit if pool is full
     * @param _data Additional data for the deposit operation
     */
    function deposit(
        uint256 _amount,
        bool _shouldQueue,
        bytes[] calldata _data
    ) external;

    /**
     * @notice Withdraws tokens from the priority pool
     * @dev Complex withdrawal function supporting partial withdrawals, queuing, and Merkle proofs
     * @param _amountToWithdraw The amount to withdraw
     * @param _amount Total amount context for the withdrawal
     * @param _sharesAmount The share amount for the withdrawal
     * @param _merkleProof Merkle proof for distribution verification
     * @param _shouldUnqueue Whether to unqueue pending withdrawals
     * @param _shouldQueueWithdrawal Whether to queue this withdrawal if not immediately processable
     * @param _data Additional data for the withdrawal operation
     */
    function withdraw(
        uint256 _amountToWithdraw,
        uint256 _amount,
        uint256 _sharesAmount,
        bytes32[] calldata _merkleProof,
        bool _shouldUnqueue,
        bool _shouldQueueWithdrawal,
        bytes[] calldata _data
    ) external;

    /**
     * @notice Claims LSD tokens from the pool
     * @dev Allows users to claim their liquid staking derivative tokens using Merkle proofs
     * @param _amount The amount to claim
     * @param _sharesAmount The share amount for the claim
     * @param _merkleProof Merkle proof for distribution verification
     */
    function claimLSDTokens(
        uint256 _amount,
        uint256 _sharesAmount,
        bytes32[] calldata _merkleProof
    ) external;

    /**
     * @notice Pauses the pool for updates
     * @dev Admin function to pause pool operations before distribution updates
     */
    function pauseForUpdate() external;

    /**
     * @notice Sets the operational status of the pool
     * @dev Admin function to change pool status between OPEN, DRAINING, and CLOSED
     * @param _status The new PoolStatus to set
     */
    function setPoolStatus(PoolStatus _status) external;

    /**
     * @notice Updates the reward distribution with new Merkle tree data
     * @dev Admin function to update the distribution root and associated metadata
     * @param _merkleRoot The new Merkle root for the distribution
     * @param _ipfsHash The IPFS hash containing distribution metadata
     * @param _amountDistributed The total amount being distributed
     * @param _sharesAmountDistributed The total shares amount being distributed
     */
    function updateDistribution(
        bytes32 _merkleRoot,
        bytes32 _ipfsHash,
        uint256 _amountDistributed,
        uint256 _sharesAmountDistributed
    ) external;

    /**
     * @notice Executes queued withdrawals in batch
     * @dev Processes multiple queued withdrawal requests to improve efficiency
     * @param _amount The total amount to process from the queue
     * @param _data Additional data for the execution
     */
    function executeQueuedWithdrawals(
        uint256 _amount,
        bytes[] calldata _data
    ) external;

    /**
     * @notice Checks if upkeep is needed (Chainlink Automation compatible)
     * @dev Part of Chainlink Automation interface to determine if performUpkeep should be called
     * @param checkData Data passed from the Chainlink Automation network
     * @return upkeepNeeded Whether upkeep is needed
     * @return performData Data to pass to performUpkeep function
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice Performs automated upkeep tasks (Chainlink Automation compatible)
     * @dev Executes automated maintenance tasks when called by Chainlink Automation
     * @param _performData Data from checkUpkeep to guide the upkeep actions
     */
    function performUpkeep(bytes calldata _performData) external;
}
