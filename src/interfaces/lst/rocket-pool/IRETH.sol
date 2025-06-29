// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IRETH
 * @notice Interface for RocketPool's rETH liquid staking token
 * @dev This interface extends ERC20 with RocketPool-specific functionality for rETH,
 *      the liquid staking token that represents staked ETH in the RocketPool protocol.
 *      rETH appreciates in value relative to ETH as staking rewards accrue.
 */
interface IRETH is IERC20 {
    /**
     * @notice Converts rETH amount to its equivalent ETH value
     * @dev Calculates the current ETH value of a given rETH amount based on the
     *      current exchange rate. The rate increases over time as staking rewards accrue.
     * @param _rethAmount The amount of rETH to convert
     * @return The equivalent ETH value
     */
    function getEthValue(uint256 _rethAmount) external view returns (uint256);

    /**
     * @notice Converts ETH amount to its equivalent rETH value
     * @dev Calculates how much rETH would be received for a given ETH amount
     *      based on the current exchange rate.
     * @param _ethAmount The amount of ETH to convert
     * @return The equivalent rETH value
     */
    function getRethValue(uint256 _ethAmount) external view returns (uint256);

    /**
     * @notice Gets the current rETH to ETH exchange rate
     * @dev Returns the current exchange rate between rETH and ETH.
     *      This rate increases over time as staking rewards are distributed.
     * @return The current exchange rate (rETH value in ETH)
     */
    function getExchangeRate() external view returns (uint256);

    /**
     * @notice Gets the total collateral backing rETH tokens
     * @dev Returns the total amount of ETH collateral held by the RocketPool protocol
     *      to back all outstanding rETH tokens.
     * @return The total collateral amount in ETH
     */
    function getTotalCollateral() external view returns (uint256);

    /**
     * @notice Gets the collateralization rate of rETH
     * @dev Returns the ratio of total collateral to total rETH supply,
     *      indicating the backing ratio of the liquid staking token.
     * @return The collateral rate as a ratio
     */
    function getCollateralRate() external view returns (uint256);

    /**
     * @notice Deposits excess ETH into the RocketPool protocol
     * @dev Allows depositing additional ETH into RocketPool when there's
     *      excess capacity. This function is typically used by the protocol itself.
     */
    function depositExcess() external payable;

    /**
     * @notice Deposits excess collateral into the protocol
     * @dev Manages excess collateral deposits within the RocketPool system.
     *      This is an internal protocol function for collateral management.
     */
    function depositExcessCollateral() external;

    /**
     * @notice Mints new rETH tokens
     * @dev Creates new rETH tokens backed by the provided ETH amount.
     *      This function is typically called during the staking process.
     * @param _ethAmount The amount of ETH backing the new rETH tokens
     * @param _to The address to receive the newly minted rETH tokens
     */
    function mint(uint256 _ethAmount, address _to) external;

    /**
     * @notice Burns rETH tokens
     * @dev Destroys rETH tokens, typically as part of the unstaking process.
     *      This function is used when users want to convert rETH back to ETH.
     * @param _rethAmount The amount of rETH tokens to burn
     */
    function burn(uint256 _rethAmount) external;
}
