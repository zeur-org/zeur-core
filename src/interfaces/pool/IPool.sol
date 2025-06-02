// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IPool {
    // Pack into 4 slots
    struct CollateralConfiguration {
        uint256 supplyCap;
        uint256 borrowCap;
        address colToken;
        address colTokenVault;
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
        address colToken;
        address debtToken;
        uint16 reserveFactor; // e.g. 1000 for 10% (in bps)
        bool isFrozen;
        bool isPaused;
    }

    function supply(address token, uint256 amount, address from) external;

    function withdraw(address token, uint256 amount, address to) external;

    function borrow(address token, uint256 amount, address to) external;

    function repay(address token, uint256 amount, address from) external;

    function liquidate(address token, uint256 amount, address from) external;

    function spotRepay(
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralMinPrice,
        uint256 collateralMaxPrice,
        address debtToken,
        uint256 debtAmount,
        address from
    ) external;

    function setAutoRepay(
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralMinPrice,
        uint256 collateralMaxPrice,
        address debtToken,
        uint256 debtAmount,
        address from
    ) external;

    function executeAutoRepay(
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralMinPrice,
        uint256 collateralMaxPrice,
        address debtToken,
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

    function getCollateralAssetData(
        address collateralAsset
    ) external view returns (uint256);

    function getDebtAssetData(
        address debtAsset
    ) external view returns (uint256);

    function getUserConfiguration(address user) external view returns (uint256);

    function getUserCollateralData(
        address user
    ) external view returns (uint256);

    function getUserDebtData(address user) external view returns (uint256);

    function getUserData(address user) external view returns (uint256);
}
