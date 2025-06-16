// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPool} from "./IPool.sol";

interface IProtocolSettingManager {
    function initCollateralAsset(
        address collateralAsset,
        IPool.CollateralConfiguration memory collateralConfiguration
    ) external;

    function initDebtAsset(
        address debtAsset,
        IPool.DebtConfiguration memory debtConfiguration
    ) external;

    function setCollateralConfiguration(
        address collateralAsset,
        IPool.CollateralConfiguration memory collateralConfiguration
    ) external;

    function setCollateralLtv(address collateralAsset, uint16 ltv) external;

    function setCollateralLiquidationThreshold(
        address collateralAsset,
        uint16 liquidationThreshold
    ) external;

    function setCollateralLiquidationBonus(
        address collateralAsset,
        uint16 liquidationBonus
    ) external;

    function setCollateralLiquidationProtocolFee(
        address collateralAsset,
        uint16 liquidationProtocolFee
    ) external;

    function setCollateralReserveFactor(
        address collateralAsset,
        uint16 reserveFactor
    ) external;

    function setCollateralSupplyCap(
        address collateralAsset,
        uint256 supplyCap
    ) external;

    function setCollateralBorrowCap(
        address collateralAsset,
        uint256 borrowCap
    ) external;

    function setDebtConfiguration(
        address debtAsset,
        IPool.DebtConfiguration memory debtConfiguration
    ) external;

    function setDebtSupplyCap(address debtAsset, uint256 supplyCap) external;

    function setDebtReserveFactor(
        address debtAsset,
        uint16 reserveFactor
    ) external;

    function freezeCollateral(address collateralAsset, bool freeze) external;

    function freezeDebt(address debtAsset, bool freeze) external;

    function pauseCollateral(address collateralAsset, bool pause) external;

    function pauseDebt(address debtAsset, bool pause) external;
}
