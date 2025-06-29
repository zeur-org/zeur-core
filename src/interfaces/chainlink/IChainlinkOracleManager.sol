// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IChainlinkOracleManager
 * @notice Interface for managing Chainlink price oracles in the protocol
 * @dev This interface provides functionality to set, retrieve, and query Chainlink price feeds
 *      for various assets in the protocol. It serves as the centralized oracle management system
 *      ensuring accurate and reliable price data for risk management and liquidations.
 */
interface IChainlinkOracleManager {
    /**
     * @notice Thrown when an invalid price is received from a Chainlink oracle
     * @param asset The address of the asset with the invalid price
     * @param price The invalid price value received from the oracle
     */
    error ChainlinkOracleManager__InvalidPrice(address asset, int256 price);

    /**
     * @notice Emitted when a Chainlink oracle is set for an asset
     * @param asset The address of the asset for which the oracle was set
     * @param oracle The address of the Chainlink price feed oracle
     */
    event ChainlinkOracleSet(address indexed asset, address indexed oracle);

    /**
     * @notice Sets the Chainlink price feed oracle for a specific asset
     * @dev Associates an asset with its corresponding Chainlink price feed address.
     *      Only authorized addresses (typically admin) can call this function.
     * @param asset The address of the asset (e.g., ETH, LINK, stETH)
     * @param oracle The address of the Chainlink price feed for the asset
     */
    function setChainlinkOracle(address asset, address oracle) external;

    /**
     * @notice Retrieves the Chainlink oracle address for a specific asset
     * @dev Returns the price feed address associated with the given asset.
     * @param asset The address of the asset to query
     * @return The address of the Chainlink price feed oracle
     */
    function getChainlinkOracle(address asset) external view returns (address);

    /**
     * @notice Gets the current price of a specific asset in USD
     * @dev Queries the associated Chainlink oracle and returns the latest price.
     *      The price is typically returned with 8 decimal places (Chainlink standard).
     * @param asset The address of the asset to get the price for
     * @return The current price of the asset in USD (scaled by oracle decimals)
     */
    function getAssetPrice(address asset) external view returns (uint256);

    /**
     * @notice Gets the current prices of multiple assets in USD
     * @dev Batch query function that returns prices for multiple assets in a single call.
     *      Useful for efficient price fetching in liquidation and health factor calculations.
     * @param assets Array of asset addresses to get prices for
     * @return Array of current prices corresponding to the input assets
     */
    function getAssetsPrices(
        address[] calldata assets
    ) external view returns (uint256[] memory);
}
