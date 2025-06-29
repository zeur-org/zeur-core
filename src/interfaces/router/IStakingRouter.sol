// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IStakingRouter
 * @notice Interface for staking router contracts that interact with different LST protocols
 * @dev This interface defines the standard functionality for staking routers that handle
 *      interactions with various liquid staking protocols (Lido, RocketPool, EtherFi, etc.).
 *      Each router is specific to one staking protocol and handles the conversion between
 *      underlying assets and their liquid staking token equivalents.
 */
interface IStakingRouter {
    /**
     * @notice Thrown when an invalid amount is provided for staking/unstaking
     */
    error StakingRouter_InvalidAmount();

    /**
     * @notice Thrown when an invalid receiver address is provided
     */
    error StakingRouter_InvalidReceiver();

    /**
     * @notice Thrown when a token transfer operation fails
     */
    error StakingRouter_FailedToTransfer();

    /**
     * @notice Thrown when the underlying token address is invalid or unsupported
     */
    error StakingRouter_InvalidUnderlyingToken();

    /**
     * @notice Thrown when the staked token address is invalid or unsupported
     */
    error StakingRouter_InvalidStakedToken();

    /**
     * @notice Stakes underlying tokens into the LST protocol
     * @dev Converts underlying tokens (e.g., ETH) into liquid staking tokens (e.g., stETH).
     *      For ETH-based protocols, this function should be payable and msg.value should equal amount.
     *      For token-based protocols, tokens should be transferred before calling this function.
     * @param from The address providing the underlying tokens (typically the vault)
     * @param amount The amount of underlying tokens to stake
     */
    function stake(address from, uint256 amount) external payable;

    /**
     * @notice Unstakes LST tokens back to underlying tokens
     * @dev Converts liquid staking tokens back to underlying tokens and sends them to the recipient.
     *      This may involve immediate conversion or entering a withdrawal queue depending on the protocol.
     * @param to The address to receive the unstaked underlying tokens
     * @param amount The amount of LST tokens to unstake
     */
    function unstake(address to, uint256 amount) external;

    /**
     * @notice Returns the address of the underlying token accepted by this router
     * @dev Returns the base asset that can be staked (e.g., ETH address for ETH-based LSTs,
     *      LINK address for LINK-based LSTs). For native ETH, this typically returns address(0).
     * @return The address of the underlying token
     */
    function getUnderlyingToken() external view returns (address);

    /**
     * @notice Returns the address of the staked token received after staking
     * @dev Returns the liquid staking token that is minted when staking underlying tokens
     *      (e.g., stETH for Lido, rETH for RocketPool, weETH for EtherFi).
     * @return The address of the staked token
     */
    function getStakedToken() external view returns (address);

    /**
     * @notice Returns the total amount of underlying tokens managed by this router
     * @dev Calculates the total underlying token value of all staked positions managed
     *      by this router, useful for vault accounting and TVL calculations.
     * @return The total amount of underlying tokens represented by the router's positions
     */
    function getTotalStakedUnderlying() external view returns (uint256);

    /**
     * @notice Returns the current exchange rate between staked and underlying tokens
     * @dev Provides the conversion rate from staked tokens to underlying tokens.
     *      This rate typically increases over time as staking rewards accrue.
     *      The rate is usually expressed with 18 decimal places for precision.
     * @return The exchange rate (staked token value in underlying tokens)
     */
    function getExchangeRate() external view returns (uint256);

    /**
     * @notice Returns both the staked token address and current exchange rate
     * @dev Convenience function that combines getStakedToken() and getExchangeRate()
     *      calls to reduce gas costs when both values are needed.
     * @return stakedToken The address of the staked token
     * @return exchangeRate The current exchange rate
     */
    function getStakedTokenAndExchangeRate()
        external
        view
        returns (address stakedToken, uint256 exchangeRate);

    // Additional functions for future enhancements:
    //
    // /// @notice Returns the available deposit amount of the underlying token
    // function getAvailableDepositAmount() external view returns (uint256);
    //
    // /// @notice Returns the available withdraw amount of the staked token
    // function getAvailableWithdrawAmount() external view returns (uint256);
    //
    // /// @notice Returns the queue time for deposit if exist
    // function getQueueTimeForDeposit() external view returns (uint256);
    //
    // /// @notice Returns the queue time for withdrawal if exist
    // function getQueueTimeForWithdrawal() external view returns (uint256);
}
