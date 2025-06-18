// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {IPool} from "./IPool.sol";

interface IPoolData {
    struct AssetData {
        IPool.AssetType assetType;
        address asset;
        address colToken;
        address debtToken;
        address tokenVault;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 totalSupply; // total supply of the asset, used for both collateral and EUR assets
        uint256 totalBorrow; // total borrow of the asset, only used for EUR
        uint256 totalShares; // total shares of the asset, only used for EUR
        uint256 utilizationRate; // utilization rate of the asset, only used for EUR assets (totalBorrow/totalSupply)
        uint256 supplyRate; // in bps
        uint256 borrowRate; // in bps
        uint16 ltv; // in bps, only used for collateral
        uint16 liquidationThreshold; // in bps, only used for collateral
        uint16 liquidationBonus; // in bps, only used for collateral
        uint16 liquidationProtocolFee; // in bps, only used for collateral
        uint16 reserveFactor; // in bps, used for both collateral and EUR
        uint8 decimals; // decimals of the asset
        bool isFrozen; // if the asset is frozen (can withdraw/repay/liquidate but can not supply/borrow)
        bool isPaused; // if the asset is paused (can not supply/withdraw/repay/borrow/liquidate)
        StakedTokenData[] stakedTokens; // staked tokens of the asset, only used for ETH/LINK (store data of LSTs)
    }

    struct UserData {
        uint256 totalCollateralValue;
        uint256 totalDebtValue;
        uint256 availableBorrowsValue;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
        UserCollateralData[] userCollateralData;
        UserDebtData[] userDebtData;
    }

    struct StakedTokenData {
        address stakedToken; // staked token address (LSTs: stETH, rETH, eETH, mETH or stLINK)
        uint256 underlyingAmount; // underlying amount of the asset that originally staked in each LST protocol (total underlying amount = totalSupply of the asset)
        uint256 stakedAmount; // the amount of each LST token holding by protocol
    }

    struct UserCollateralData {
        address collateralAsset; // collateral asset address
        uint256 supplyBalance; // the amount of collateral asset that user supplied
    }

    struct UserDebtData {
        address debtAsset; // debt asset address
        uint256 supplyBalance; // the amount of debt asset that user supplied
        uint256 borrowBalance; // the amount of debt asset that user borrowed
    }

    // Main getters to use for UI
    function getCollateralAssetList() external view returns (address[] memory);

    function getDebtAssetList() external view returns (address[] memory);

    function getAssetData(
        address asset
    ) external view returns (AssetData memory);

    function getUserData(address user) external view returns (UserData memory);

    // Complementary function to use if needed
    function getCollateralAssetConfiguration(
        address collateralAsset
    ) external view returns (IPool.CollateralConfiguration memory);

    function getCollateralAssetsConfiguration(
        address[] memory collateralAssets
    ) external view returns (IPool.CollateralConfiguration[] memory);

    function getDebtAssetConfiguration(
        address debtAsset
    ) external view returns (IPool.DebtConfiguration memory);

    function getDebtAssetsConfiguration(
        address[] memory debtAssets
    ) external view returns (IPool.DebtConfiguration[] memory);
}
