// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title ILido
 * @notice Interface for Lido liquid staking protocol (stETH)
 * @dev This interface provides access to Lido's ETH staking functionality, allowing
 *      users to stake ETH and receive stETH tokens in return. stETH tokens represent
 *      staked ETH in the Ethereum 2.0 beacon chain and accrue staking rewards over time.
 */
interface ILido {
    /**
     * @notice Stakes ETH and mints stETH tokens to the sender
     * @dev Submits ETH for staking in the Ethereum 2.0 beacon chain through Lido.
     *      The function mints stETH tokens at a 1:1 ratio initially, but the value
     *      of stETH increases over time as staking rewards accrue.
     * @param _referral Address of the referrer (can be zero address if no referrer)
     * @return Amount of stETH tokens minted to the sender
     */
    function submit(address _referral) external payable returns (uint256);
}
