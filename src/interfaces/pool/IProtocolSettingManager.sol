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
        uint96 supplyCap
    ) external;

    function setCollateralBorrowCap(
        address collateralAsset,
        uint96 borrowCap
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

    function freezeCollateral(address collateralAsset) external;

    function freezeDebt(address debtAsset) external;

    function pauseCollateral(address collateralAsset) external;

    function pauseDebt(address debtAsset) external;

    function unfreezeCollateral(address collateralAsset) external;

    function unfreezeDebt(address debtAsset) external;

    function unpauseCollateral(address collateralAsset) external;

    function unpauseDebt(address debtAsset) external;
}
