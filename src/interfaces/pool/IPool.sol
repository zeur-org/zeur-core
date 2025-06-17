// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IChainlinkOracleManager} from "../../interfaces/chainlink/IChainlinkOracleManager.sol";

interface IPool {
    error Pool_AssetNotAllowed(address asset);
    error Pool_AssetAlreadyInitialized(address asset);
    error Pool_InvalidAmount();
    error Pool_CollateralFrozen();
    error Pool_CollateralPaused();
    error Pool_DebtFrozen();
    error Pool_DebtPaused();
    error Pool_SupplyCapExceeded();
    error Pool_BorrowCapExceeded();
    error Pool_InsufficientAvailableBorrowsValue();
    error Pool_InsufficientHealthFactor();

    enum UserAction {
        Supply,
        Withdraw,
        Borrow,
        Repay,
        Liquidate
    }

    struct UserAccountData {
        uint256 totalCollateralValue;
        uint256 totalDebtValue;
        uint256 availableBorrowsValue;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
    }

    struct UserCalculationData {
        address[] collateralAssets;
        address[] debtAssets;
        uint16 collateralLength; // length of collateralAssets
        uint16 debtLength; // length of debtAssets
        address cacheAsset; // underlying asset, used for caching the current asset in a loop
        IERC20Metadata cacheTokenizedAsset; // colToken or debtToken, used for caching the current tokenized asset in a loop
        IChainlinkOracleManager oracleManager;
        uint256 collateralValue;
        uint256 totalBorrowableValue;
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

    event Supply(
        address indexed asset,
        uint256 amount,
        address indexed from,
        address indexed caller
    );

    event Withdraw(
        address indexed asset,
        uint256 amount,
        address indexed to,
        address indexed caller
    );

    event Borrow(
        address indexed asset,
        uint256 amount,
        address indexed to,
        address indexed caller
    );

    event Repay(
        address indexed asset,
        uint256 amount,
        address indexed from,
        address indexed caller
    );

    event Liquidate(
        address indexed collateralAsset,
        address indexed debtAsset,
        uint256 debtAmount,
        address from,
        address liquidator
    );

    event InitCollateralAsset(
        address indexed collateralAsset,
        CollateralConfiguration collateralConfiguration
    );

    event InitDebtAsset(
        address indexed debtAsset,
        DebtConfiguration debtConfiguration
    );

    event SetCollateralConfiguration(
        address indexed collateralAsset,
        CollateralConfiguration collateralConfiguration
    );

    event SetDebtConfiguration(
        address indexed debtAsset,
        DebtConfiguration debtConfiguration
    );

    event SetChainlinkOracleManager(address indexed oracleManager);

    function supply(
        address asset,
        uint256 amount,
        address from
    ) external payable;

    function withdraw(address asset, uint256 amount, address to) external;

    function borrow(address asset, uint256 amount, address to) external;

    function repay(address asset, uint256 amount, address from) external;

    function liquidate(
        address collateralAsset,
        address debtAsset,
        uint256 debtAmount,
        address from
    ) external;

    function initCollateralAsset(
        address collateralAsset,
        CollateralConfiguration memory collateralConfiguration
    ) external;

    function initDebtAsset(
        address debtAsset,
        DebtConfiguration memory debtConfiguration
    ) external;

    function setCollateralConfiguration(
        address collateralAsset,
        CollateralConfiguration memory collateralConfiguration
    ) external;

    function setDebtConfiguration(
        address debtAsset,
        DebtConfiguration memory debtConfiguration
    ) external;

    function getCollateralAssetList() external view returns (address[] memory);

    function getDebtAssetList() external view returns (address[] memory);

    function getCollateralAssetConfiguration(
        address collateralAsset
    ) external view returns (CollateralConfiguration memory);

    function getDebtAssetConfiguration(
        address debtAsset
    ) external view returns (DebtConfiguration memory);

    function getUserAccountData(
        address user
    ) external view returns (UserAccountData memory);

    // function getUserConfiguration(address user) external view returns (uint256);

    // function spotRepay(
    //     address collateralAsset,
    //     uint256 collateralAmount,
    //     uint256 collateralMinPrice,
    //     uint256 collateralMaxPrice,
    //     address debtAsset,
    //     uint256 debtAmount,
    //     address from
    // ) external;

    // function setAutoRepay(
    //     address collateralAsset,
    //     uint256 collateralAmount,
    //     uint256 collateralMinPrice,
    //     uint256 collateralMaxPrice,
    //     address debtAsset,
    //     uint256 debtAmount,
    //     address from
    // ) external;

    // function executeAutoRepay(
    //     address collateralAsset,
    //     uint256 collateralAmount,
    //     uint256 collateralMinPrice,
    //     uint256 collateralMaxPrice,
    //     address debtAsset,
    //     uint256 debtAmount,
    //     address from
    // ) external;

    // function getCollateralAssetData(
    //     address collateralAsset
    // ) external view returns (uint256);

    // function getDebtAssetData(
    //     address debtAsset
    // ) external view returns (uint256);
}
