// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolData} from "../interfaces/pool/IPoolData.sol";
import {IPool} from "../interfaces/pool/IPool.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract PoolData is IPoolData {
    IPool private immutable _pool;

    constructor(address pool) {
        _pool = IPool(pool);
    }

    function getUserAccountData(
        address user
    ) external view returns (IPool.UserAccountData memory) {}

    function getUserCollateralData(
        address user
    )
        external
        view
        override
        returns (
            address[] memory collateralAssets,
            uint256[] memory collateralAmounts
        )
    {
        collateralAssets = _pool.getCollateralAssetList();
        uint256 length = collateralAssets.length;
        collateralAmounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            collateralAmounts[i] = IERC20(
                _pool
                    .getCollateralAssetConfiguration(collateralAssets[i])
                    .colToken
            ).balanceOf(user);
        }

        return (collateralAssets, collateralAmounts);
    }

    function getUserDebtData(
        address user
    )
        external
        view
        override
        returns (address[] memory debtAssets, uint256[] memory debtAmounts)
    {
        debtAssets = _pool.getDebtAssetList();
        uint256 length = debtAssets.length;
        debtAmounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            debtAmounts[i] = IERC20(
                _pool.getDebtAssetConfiguration(debtAssets[i]).debtToken
            ).balanceOf(user);
        }
    }
}
