// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {IPool} from "./IPool.sol";

interface IUIPoolData {
    enum AssetType {
        Collateral,
        Debt
    }
    struct AssetData {
        AssetType assetType;
        address asset;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 totalSupply; // total supply of the asset, used for both collateral and EUR assets
        uint256 totalBorrow; // total borrow of the asset, only used for EUR
        uint256 totalShares; // total shares of the asset, only used for EUR
        uint256 utilizationRate; // utilization rate of the asset, only used for EUR assets (totalBorrow/totalSupply)
        uint256 supplyRate; // in bps
        uint256 borrowRate; // in bps
        uint16 ltv; // in bps
        uint16 liquidationThreshold; // in bps
        uint16 liquidationBonus; // in bps
        uint16 liquidationProtocolFee; // in bps
        uint16 reserveFactor; // in bps
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

    // Pack into 4 slots
    struct CollateralConfiguration {
        uint256 supplyCap;
        uint256 borrowCap;
        address colToken;
        address tokenVault;
        uint16 ltv; // e.g. 7500 for 75% (in bps)
        uint16 liquidationThreshold; // e.g. 8000 for 80%
        uint16 liquidationBonus; // e.g. 10500 for 5% bonus (in bps)
        uint16 liquidationProtocolFee; // e.g. 1000 for 10% fee on bonus (in bps)
        uint16 reserveFactor; // e.g. 1000 for 10% (in bps)
        bool isFrozen;
        bool isPaused;
    }

    // Pack into 4 slots
    struct DebtConfiguration {
        uint256 supplyCap;
        uint256 borrowCap;
        address colToken;
        address debtToken;
        uint16 reserveFactor; // e.g. 1000 for 10% (in bps)
        bool isFrozen;
        bool isPaused;
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
    ) external view returns (CollateralConfiguration memory);

    function getCollateralAssetsConfiguration(
        address[] memory collateralAssets
    ) external view returns (CollateralConfiguration[] memory);

    function getDebtAssetConfiguration(
        address debtAsset
    ) external view returns (DebtConfiguration memory);

    function getDebtAssetsConfiguration(
        address[] memory debtAssets
    ) external view returns (DebtConfiguration[] memory);
}
