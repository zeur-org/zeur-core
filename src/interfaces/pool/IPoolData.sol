// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {IPool} from "./IPool.sol";

interface IPoolData {
    function getUserAccountData(
        address user
    ) external view returns (IPool.UserAccountData memory);

    function getUserCollateralData(
        address user
    )
        external
        view
        returns (
            address[] memory collateralAssets,
            uint256[] memory collateralAmounts
        );

    function getUserDebtData(
        address user
    )
        external
        view
        returns (address[] memory debtAssets, uint256[] memory debtAmounts);
}
