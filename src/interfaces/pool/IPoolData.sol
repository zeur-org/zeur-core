// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {IPool} from "./IPool.sol";

/**
 * @title IPoolData
 * @notice Interface for accessing pool and user data in a structured format
 * @dev This interface provides comprehensive data access functions for the lending protocol,
 *      including asset configurations, user positions, and market information
 */
interface IPoolData {
    /**
     * @notice Comprehensive data structure for asset information
     * @dev Contains all relevant information about an asset including configuration,
     *      market data, and staking information for liquid staking tokens
     */
    struct AssetData {
        IPool.AssetType assetType; /// @dev Type of asset (NoneAsset, Collateral, Debt)
        address asset; /// @dev Address of the underlying asset
        address colToken; /// @dev Address of the collateral token (if applicable)
        address debtToken; /// @dev Address of the debt token (if applicable)
        address tokenVault; /// @dev Address of the token vault (if applicable)
        uint256 price; /// @dev Current price of the asset in USD (with appropriate decimals)
        uint256 supplyCap; /// @dev Maximum supply cap for the asset
        uint256 borrowCap; /// @dev Maximum borrow cap for the asset
        uint256 totalSupply; /// @dev Total supply of the asset, used for both collateral and EUR assets
        uint256 totalBorrow; /// @dev Total borrow of the asset, only used for EUR assets
        uint256 totalShares; /// @dev Total shares of the asset, only used for EUR assets
        uint256 utilizationRate; /// @dev Utilization rate (totalBorrow/totalSupply), only for EUR assets
        uint256 supplyRate; /// @dev Annual supply rate in basis points
        uint256 borrowRate; /// @dev Annual borrow rate in basis points
        uint16 ltv; /// @dev Loan-to-value ratio in basis points, only used for collateral
        uint16 liquidationThreshold; /// @dev Liquidation threshold in basis points, only used for collateral
        uint16 liquidationBonus; /// @dev Liquidation bonus in basis points, only used for collateral
        uint16 liquidationProtocolFee; /// @dev Protocol fee on liquidation bonus in basis points, only used for collateral
        uint16 reserveFactor; /// @dev Reserve factor in basis points, used for both collateral and EUR assets
        uint8 decimals; /// @dev Number of decimals for the asset
        bool isFrozen; /// @dev If true, asset is frozen (can withdraw/repay/liquidate but not supply/borrow)
        bool isPaused; /// @dev If true, asset is paused (no operations allowed)
        StakedTokenData[] stakedTokens; /// @dev Array of staked token data for ETH/LINK (LST information)
    }

    /**
     * @notice Comprehensive user position and health data
     * @dev Contains user's account information including collateral, debt, and health metrics
     */
    struct UserData {
        uint256 totalCollateralValue; /// @dev Total value of user's collateral in USD
        uint256 totalDebtValue; /// @dev Total value of user's debt in USD
        uint256 availableBorrowsValue; /// @dev Available borrowing capacity in USD
        uint256 currentLiquidationThreshold; /// @dev Weighted average liquidation threshold
        uint256 ltv; /// @dev Current loan-to-value ratio
        uint256 healthFactor; /// @dev Health factor (>1 is safe, <1 can be liquidated)
        UserCollateralData[] userCollateralData; /// @dev Array of user's collateral positions
        UserDebtData[] userDebtData; /// @dev Array of user's debt positions
    }

    /**
     * @notice Information about staked tokens (Liquid Staking Tokens)
     * @dev Contains data about LSTs like stETH, rETH, eETH, mETH, or stLINK
     */
    struct StakedTokenData {
        address stakedToken; /// @dev Address of the staked token (LST)
        uint256 underlyingAmount; /// @dev Original underlying amount staked in each LST protocol
        uint256 stakedAmount; /// @dev Current amount of LST tokens held by the protocol
    }

    /**
     * @notice User's collateral position data
     * @dev Contains information about a user's supply position in a collateral asset
     */
    struct UserCollateralData {
        address collateralAsset; /// @dev Address of the collateral asset
        uint256 supplyBalance; /// @dev Amount of collateral asset that user has supplied
    }

    /**
     * @notice User's debt position data
     * @dev Contains information about a user's supply and borrow positions in a debt asset
     */
    struct UserDebtData {
        address debtAsset; /// @dev Address of the debt asset
        uint256 supplyBalance; /// @dev Amount of debt asset that user has supplied
        uint256 borrowBalance; /// @dev Amount of debt asset that user has borrowed
    }

    /**
     * @notice Get list of all collateral assets
     * @dev Main getter function for UI to retrieve all available collateral assets
     * @return Array of collateral asset addresses
     */
    function getCollateralAssetList() external view returns (address[] memory);

    /**
     * @notice Get list of all debt assets
     * @dev Main getter function for UI to retrieve all available debt assets
     * @return Array of debt asset addresses
     */
    function getDebtAssetList() external view returns (address[] memory);

    /**
     * @notice Get comprehensive data for a specific asset
     * @dev Main getter function for UI to retrieve all asset information including
     *      configuration, market data, and staking information
     * @param asset Address of the asset to query
     * @return AssetData struct containing all asset information
     */
    function getAssetData(
        address asset
    ) external view returns (AssetData memory);

    /**
     * @notice Get comprehensive user position and health data
     * @dev Main getter function for UI to retrieve all user information including
     *      collateral positions, debt positions, and health metrics
     * @param user Address of the user to query
     * @return UserData struct containing all user information
     */
    function getUserData(address user) external view returns (UserData memory);

    /**
     * @notice Get collateral asset configuration
     * @dev Complementary function to retrieve detailed configuration for a single collateral asset
     * @param collateralAsset Address of the collateral asset
     * @return CollateralConfiguration struct from IPool interface
     */
    function getCollateralAssetConfiguration(
        address collateralAsset
    ) external view returns (IPool.CollateralConfiguration memory);

    /**
     * @notice Get multiple collateral assets configurations
     * @dev Complementary function to retrieve detailed configurations for multiple collateral assets
     * @param collateralAssets Array of collateral asset addresses
     * @return Array of CollateralConfiguration structs from IPool interface
     */
    function getCollateralAssetsConfiguration(
        address[] memory collateralAssets
    ) external view returns (IPool.CollateralConfiguration[] memory);

    /**
     * @notice Get debt asset configuration
     * @dev Complementary function to retrieve detailed configuration for a single debt asset
     * @param debtAsset Address of the debt asset
     * @return DebtConfiguration struct from IPool interface
     */
    function getDebtAssetConfiguration(
        address debtAsset
    ) external view returns (IPool.DebtConfiguration memory);

    /**
     * @notice Get multiple debt assets configurations
     * @dev Complementary function to retrieve detailed configurations for multiple debt assets
     * @param debtAssets Array of debt asset addresses
     * @return Array of DebtConfiguration structs from IPool interface
     */
    function getDebtAssetsConfiguration(
        address[] memory debtAssets
    ) external view returns (IPool.DebtConfiguration[] memory);
}
