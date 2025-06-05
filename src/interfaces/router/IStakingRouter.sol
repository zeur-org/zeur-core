// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IStakingRouter {
    error StakingRouter_InvalidAmount();
    error StakingRouter_InvalidReceiver();
    error StakingRouter_FailedToTransfer();
    error StakingRouter_InvalidUnderlyingToken();
    error StakingRouter_InvalidStakedToken();

    /// @notice Stakes a specified amount of the underlying token
    /// @param from The address to stake from
    /// @param amount The amount to stake
    function stake(address from, uint256 amount) external payable;

    /// @notice Unstakes a specified amount of the staked token
    /// @param to The address to receive the tokens
    /// @param amount The amount to unstake
    function unstake(address to, uint256 amount) external;

    /// @notice Returns the underlying token accepted by the strategy (e.g., ETH, LINK)
    function getUnderlyingToken() external view returns (address);

    /// @notice Returns the token received after staking (e.g., stETH, rETH)
    function getStakedToken() external view returns (address);

    /// @notice Returns the total amount of underlying tokens managed by the strategy
    function getTotalStakedUnderlying() external view returns (uint256);

    /// @notice Returns the exchange rate of the staked token to the underlying token
    function getExchangeRate() external view returns (uint256);

    // /// @notice Returns the available deposit amount of the underlying token
    // function getAvailableDepositAmount() external view returns (uint256);

    // /// @notice Returns the available withdraw amount of the staked token
    // function getAvailableWithdrawAmount() external view returns (uint256);

    // /// @notice Returns the queue time for deposit if exist
    // function getQueueTimeForDeposit() external view returns (uint256);

    // /// @notice Returns the queue time for withdrawal if exist
    // function getQueueTimeForWithdrawal() external view returns (uint256);
}
