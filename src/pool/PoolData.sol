// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolData} from "../interfaces/pool/IPoolData.sol";
import {IPool} from "../interfaces/pool/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PoolData is
    Initializable,
    AccessManagedUpgradeable,
    UUPSUpgradeable,
    IPoolData
{
    struct PoolDataStorage {
        IPool _pool;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.PoolData")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PoolDataStorageLocation =
        0xa8aa389b360af2fb603bf2e029719961e3a684805c87a9b3653cfab319e53b00;

    function _getPoolDataStorage()
        private
        pure
        returns (PoolDataStorage storage $)
    {
        assembly {
            $.slot := PoolDataStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        address pool
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        PoolDataStorage storage $ = _getPoolDataStorage();
        $._pool = IPool(pool);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

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
        PoolDataStorage storage $ = _getPoolDataStorage();
        collateralAssets = $._pool.getCollateralAssetList();
        uint256 length = collateralAssets.length;
        collateralAmounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            collateralAmounts[i] = IERC20(
                $
                    ._pool
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
        PoolDataStorage storage $ = _getPoolDataStorage();
        debtAssets = $._pool.getDebtAssetList();
        uint256 length = debtAssets.length;
        debtAmounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            debtAmounts[i] = IERC20(
                $._pool.getDebtAssetConfiguration(debtAssets[i]).debtToken
            ).balanceOf(user);
        }
    }
}
