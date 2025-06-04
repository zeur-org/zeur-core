// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IStakingRouter {
    error StakingRouter_InvalidAmount();
    error StakingRouter_InvalidReceiver();
    error StakingRouter_FailedToTransfer();
    error StakingRouter_InvalidUnderlyingToken();
    error StakingRouter_InvalidStakedToken();

    /// @notice Stakes a specified amount of the underlying token
    /// @param amount The amount to stake
    /// @param receiver The address to receive the staked tokens
    function stake(uint256 amount, address receiver) external payable;

    /// @notice Unstakes a specified amount of the staked token
    /// @param amount The amount to unstake
    /// @param receiver The address to receive the tokens
    function unstake(uint256 amount, address receiver) external;

    /// @notice Returns the underlying token accepted by the strategy (e.g., ETH, LINK)
    function getUnderlyingToken() external view returns (address);

    /// @notice Returns the token received after staking (e.g., stETH, rETH)
    function getStakedToken() external view returns (address);

    /// @notice Returns the total amount of underlying tokens managed by the strategy
    function getTotalStakedUnderlying() external view returns (uint256);
}
