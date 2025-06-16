// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPool} from "../../interfaces/pool/IPool.sol";
import {IProtocolSettingManager} from "../../interfaces/pool/IProtocolSettingManager.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ProtocolSettingManager is
    Initializable,
    AccessManagedUpgradeable,
    UUPSUpgradeable,
    IProtocolSettingManager
{
    struct ProtocolSettingManagerStorage {
        IPool _pool;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.ProtocolSettingManager")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ProtocolSettingManagerStorageLocation =
        0x1c03345a3baecbfa5f76c98daacb964c084ba41883ee9de5881a16f46ba4f100;

    function _getProtocolSettingManagerStorage()
        private
        pure
        returns (ProtocolSettingManagerStorage storage $)
    {
        assembly {
            $.slot := ProtocolSettingManagerStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        IPool pool
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();
        $._pool = pool;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function initCollateralAsset(
        address collateralAsset,
        IPool.CollateralConfiguration memory collateralConfiguration
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        $._pool.initCollateralAsset(collateralAsset, collateralConfiguration);
    }

    function initDebtAsset(
        address debtAsset,
        IPool.DebtConfiguration memory debtConfiguration
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        $._pool.initDebtAsset(debtAsset, debtConfiguration);
    }

    function setCollateralConfiguration(
        address collateralAsset,
        IPool.CollateralConfiguration memory collateralConfiguration
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        $._pool.setCollateralConfiguration(
            collateralAsset,
            collateralConfiguration
        );
    }

    function setCollateralLtv(
        address collateralAsset,
        uint16 ltv
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.CollateralConfiguration memory collateralConfiguration = $
            ._pool
            .getCollateralAssetConfiguration(collateralAsset);

        collateralConfiguration.ltv = ltv;

        $._pool.setCollateralConfiguration(
            collateralAsset,
            collateralConfiguration
        );
    }

    function setCollateralLiquidationThreshold(
        address collateralAsset,
        uint16 liquidationThreshold
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.CollateralConfiguration memory collateralConfiguration = $
            ._pool
            .getCollateralAssetConfiguration(collateralAsset);

        collateralConfiguration.liquidationThreshold = liquidationThreshold;

        $._pool.setCollateralConfiguration(
            collateralAsset,
            collateralConfiguration
        );
    }

    function setCollateralLiquidationBonus(
        address collateralAsset,
        uint16 liquidationBonus
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.CollateralConfiguration memory collateralConfiguration = $
            ._pool
            .getCollateralAssetConfiguration(collateralAsset);

        collateralConfiguration.liquidationBonus = liquidationBonus;

        $._pool.setCollateralConfiguration(
            collateralAsset,
            collateralConfiguration
        );
    }

    function setCollateralLiquidationProtocolFee(
        address collateralAsset,
        uint16 liquidationProtocolFee
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.CollateralConfiguration memory collateralConfiguration = $
            ._pool
            .getCollateralAssetConfiguration(collateralAsset);

        collateralConfiguration.liquidationProtocolFee = liquidationProtocolFee;

        $._pool.setCollateralConfiguration(
            collateralAsset,
            collateralConfiguration
        );
    }

    function setCollateralReserveFactor(
        address collateralAsset,
        uint16 reserveFactor
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.CollateralConfiguration memory collateralConfiguration = $
            ._pool
            .getCollateralAssetConfiguration(collateralAsset);

        collateralConfiguration.reserveFactor = reserveFactor;

        $._pool.setCollateralConfiguration(
            collateralAsset,
            collateralConfiguration
        );
    }

    function setCollateralSupplyCap(
        address collateralAsset,
        uint256 supplyCap
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.CollateralConfiguration memory collateralConfiguration = $
            ._pool
            .getCollateralAssetConfiguration(collateralAsset);

        collateralConfiguration.supplyCap = supplyCap;

        $._pool.setCollateralConfiguration(
            collateralAsset,
            collateralConfiguration
        );
    }

    function setCollateralBorrowCap(
        address collateralAsset,
        uint256 borrowCap
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.CollateralConfiguration memory collateralConfiguration = $
            ._pool
            .getCollateralAssetConfiguration(collateralAsset);

        collateralConfiguration.borrowCap = borrowCap;

        $._pool.setCollateralConfiguration(
            collateralAsset,
            collateralConfiguration
        );
    }

    function setDebtConfiguration(
        address debtAsset,
        IPool.DebtConfiguration memory debtConfiguration
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        $._pool.setDebtConfiguration(debtAsset, debtConfiguration);
    }

    function setDebtSupplyCap(
        address debtAsset,
        uint256 supplyCap
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.DebtConfiguration memory debtConfiguration = $
            ._pool
            .getDebtAssetConfiguration(debtAsset);

        debtConfiguration.supplyCap = supplyCap;

        $._pool.setDebtConfiguration(debtAsset, debtConfiguration);
    }

    function setDebtBorrowCap(
        address debtAsset,
        uint256 borrowCap
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.DebtConfiguration memory debtConfiguration = $
            ._pool
            .getDebtAssetConfiguration(debtAsset);

        debtConfiguration.borrowCap = borrowCap;

        $._pool.setDebtConfiguration(debtAsset, debtConfiguration);
    }

    function setDebtReserveFactor(
        address debtAsset,
        uint16 reserveFactor
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.DebtConfiguration memory debtConfiguration = $
            ._pool
            .getDebtAssetConfiguration(debtAsset);

        debtConfiguration.reserveFactor = reserveFactor;

        $._pool.setDebtConfiguration(debtAsset, debtConfiguration);
    }

    function freezeCollateral(
        address collateralAsset,
        bool freeze
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.CollateralConfiguration memory collateralConfiguration = $
            ._pool
            .getCollateralAssetConfiguration(collateralAsset);

        collateralConfiguration.isFrozen = freeze;

        $._pool.setCollateralConfiguration(
            collateralAsset,
            collateralConfiguration
        );
    }

    function freezeDebt(address debtAsset, bool freeze) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.DebtConfiguration memory debtConfiguration = $
            ._pool
            .getDebtAssetConfiguration(debtAsset);

        debtConfiguration.isFrozen = freeze;

        $._pool.setDebtConfiguration(debtAsset, debtConfiguration);
    }

    function pauseCollateral(
        address collateralAsset,
        bool pause
    ) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.CollateralConfiguration memory collateralConfiguration = $
            ._pool
            .getCollateralAssetConfiguration(collateralAsset);

        collateralConfiguration.isPaused = pause;

        $._pool.setCollateralConfiguration(
            collateralAsset,
            collateralConfiguration
        );
    }

    function pauseDebt(address debtAsset, bool pause) external restricted {
        ProtocolSettingManagerStorage
            storage $ = _getProtocolSettingManagerStorage();

        IPool.DebtConfiguration memory debtConfiguration = $
            ._pool
            .getDebtAssetConfiguration(debtAsset);

        debtConfiguration.isPaused = pause;

        $._pool.setDebtConfiguration(debtAsset, debtConfiguration);
    }
}
