// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPool} from "./IPool.sol";

/**
 * @title IProtocolSettingManager
 * @notice Interface for managing protocol settings and configurations
 * @dev This interface provides functions to initialize and configure collateral and debt assets,
 *      including setting risk parameters, caps, and operational states. It's designed to be used
 *      by protocol administrators for managing the lending protocol's configuration.
 */
interface IProtocolSettingManager {
    /**
     * @notice Initialize a new collateral asset with its configuration
     * @dev This function adds a new asset as collateral to the protocol with the specified configuration.
     *      The asset must not already be initialized as a collateral asset.
     * @param collateralAsset The address of the asset to be added as collateral
     * @param collateralConfiguration The complete configuration for the collateral asset
     */
    function initCollateralAsset(
        address collateralAsset,
        IPool.CollateralConfiguration memory collateralConfiguration
    ) external;

    /**
     * @notice Initialize a new debt asset with its configuration
     * @dev This function adds a new asset as a debt asset to the protocol with the specified configuration.
     *      The asset must not already be initialized as a debt asset.
     * @param debtAsset The address of the asset to be added as a debt asset
     * @param debtConfiguration The complete configuration for the debt asset
     */
    function initDebtAsset(
        address debtAsset,
        IPool.DebtConfiguration memory debtConfiguration
    ) external;

    /**
     * @notice Update the complete configuration of an existing collateral asset
     * @dev This function replaces the entire configuration of a collateral asset.
     *      The asset must already be initialized as a collateral asset.
     * @param collateralAsset The address of the collateral asset to update
     * @param collateralConfiguration The new complete configuration for the collateral asset
     */
    function setCollateralConfiguration(
        address collateralAsset,
        IPool.CollateralConfiguration memory collateralConfiguration
    ) external;

    /**
     * @notice Set the loan-to-value ratio for a collateral asset
     * @dev Updates only the LTV parameter for the specified collateral asset.
     *      LTV determines the maximum borrowing power against the collateral.
     * @param collateralAsset The address of the collateral asset
     * @param ltv The new loan-to-value ratio in basis points (e.g., 7500 for 75%)
     */
    function setCollateralLtv(address collateralAsset, uint16 ltv) external;

    /**
     * @notice Set the liquidation threshold for a collateral asset
     * @dev Updates only the liquidation threshold parameter for the specified collateral asset.
     *      Liquidation threshold determines when positions become liquidatable.
     * @param collateralAsset The address of the collateral asset
     * @param liquidationThreshold The new liquidation threshold in basis points (e.g., 8000 for 80%)
     */
    function setCollateralLiquidationThreshold(
        address collateralAsset,
        uint16 liquidationThreshold
    ) external;

    /**
     * @notice Set the liquidation bonus for a collateral asset
     * @dev Updates only the liquidation bonus parameter for the specified collateral asset.
     *      Liquidation bonus is the incentive given to liquidators.
     * @param collateralAsset The address of the collateral asset
     * @param liquidationBonus The new liquidation bonus in basis points (e.g., 10500 for 5% bonus)
     */
    function setCollateralLiquidationBonus(
        address collateralAsset,
        uint16 liquidationBonus
    ) external;

    /**
     * @notice Set the liquidation protocol fee for a collateral asset
     * @dev Updates only the liquidation protocol fee parameter for the specified collateral asset.
     *      This is the protocol's share of the liquidation bonus.
     * @param collateralAsset The address of the collateral asset
     * @param liquidationProtocolFee The new protocol fee in basis points (e.g., 1000 for 10% of liquidation bonus)
     */
    function setCollateralLiquidationProtocolFee(
        address collateralAsset,
        uint16 liquidationProtocolFee
    ) external;

    /**
     * @notice Set the reserve factor for a collateral asset
     * @dev Updates only the reserve factor parameter for the specified collateral asset.
     *      Reserve factor determines the portion of interest that goes to the protocol reserve.
     * @param collateralAsset The address of the collateral asset
     * @param reserveFactor The new reserve factor in basis points (e.g., 1000 for 10%)
     */
    function setCollateralReserveFactor(
        address collateralAsset,
        uint16 reserveFactor
    ) external;

    /**
     * @notice Set the supply cap for a collateral asset
     * @dev Updates only the supply cap parameter for the specified collateral asset.
     *      Supply cap limits the maximum amount that can be supplied for this asset.
     * @param collateralAsset The address of the collateral asset
     * @param supplyCap The new supply cap (in asset's native decimals)
     */
    function setCollateralSupplyCap(
        address collateralAsset,
        uint256 supplyCap
    ) external;

    /**
     * @notice Set the borrow cap for a collateral asset
     * @dev Updates only the borrow cap parameter for the specified collateral asset.
     *      Borrow cap limits the maximum amount that can be borrowed against this collateral.
     * @param collateralAsset The address of the collateral asset
     * @param borrowCap The new borrow cap (in asset's native decimals)
     */
    function setCollateralBorrowCap(
        address collateralAsset,
        uint256 borrowCap
    ) external;

    /**
     * @notice Update the complete configuration of an existing debt asset
     * @dev This function replaces the entire configuration of a debt asset.
     *      The asset must already be initialized as a debt asset.
     * @param debtAsset The address of the debt asset to update
     * @param debtConfiguration The new complete configuration for the debt asset
     */
    function setDebtConfiguration(
        address debtAsset,
        IPool.DebtConfiguration memory debtConfiguration
    ) external;

    /**
     * @notice Set the supply cap for a debt asset
     * @dev Updates only the supply cap parameter for the specified debt asset.
     *      Supply cap limits the maximum amount that can be supplied for this debt asset.
     * @param debtAsset The address of the debt asset
     * @param supplyCap The new supply cap (in asset's native decimals)
     */
    function setDebtSupplyCap(address debtAsset, uint256 supplyCap) external;

    /**
     * @notice Set the reserve factor for a debt asset
     * @dev Updates only the reserve factor parameter for the specified debt asset.
     *      Reserve factor determines the portion of interest that goes to the protocol reserve.
     * @param debtAsset The address of the debt asset
     * @param reserveFactor The new reserve factor in basis points (e.g., 1000 for 10%)
     */
    function setDebtReserveFactor(
        address debtAsset,
        uint16 reserveFactor
    ) external;

    /**
     * @notice Freeze or unfreeze a collateral asset
     * @dev When frozen, users can withdraw/repay/liquidate but cannot supply/borrow.
     *      This is used for emergency situations or when phasing out an asset.
     * @param collateralAsset The address of the collateral asset
     * @param freeze True to freeze the asset, false to unfreeze
     */
    function freezeCollateral(address collateralAsset, bool freeze) external;

    /**
     * @notice Freeze or unfreeze a debt asset
     * @dev When frozen, users can withdraw/repay/liquidate but cannot supply/borrow.
     *      This is used for emergency situations or when phasing out an asset.
     * @param debtAsset The address of the debt asset
     * @param freeze True to freeze the asset, false to unfreeze
     */
    function freezeDebt(address debtAsset, bool freeze) external;

    /**
     * @notice Pause or unpause a collateral asset
     * @dev When paused, no operations are allowed (supply/withdraw/borrow/repay/liquidate).
     *      This is used for emergency situations requiring complete halt of operations.
     * @param collateralAsset The address of the collateral asset
     * @param pause True to pause the asset, false to unpause
     */
    function pauseCollateral(address collateralAsset, bool pause) external;

    /**
     * @notice Pause or unpause a debt asset
     * @dev When paused, no operations are allowed (supply/withdraw/borrow/repay/liquidate).
     *      This is used for emergency situations requiring complete halt of operations.
     * @param debtAsset The address of the debt asset
     * @param pause True to pause the asset, false to unpause
     */
    function pauseDebt(address debtAsset, bool pause) external;
}
