// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPool} from "../interfaces/pool/IPool.sol";
import {IPoolData} from "../interfaces/pool/IPoolData.sol";
import {IChainlinkOracleManager} from "../interfaces/chainlink/IChainlinkOracleManager.sol";
import {IVault} from "../interfaces/vault/IVault.sol";
import {IStakingRouter} from "../interfaces/router/IStakingRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";

contract PoolData is
    Initializable,
    AccessManagedUpgradeable,
    UUPSUpgradeable,
    IPoolData
{
    struct PoolDataStorage {
        IPool _pool;
        IChainlinkOracleManager _oracleManager;
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
        address pool,
        address oracleManager
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        PoolDataStorage storage $ = _getPoolDataStorage();
        $._pool = IPool(pool);
        $._oracleManager = IChainlinkOracleManager(oracleManager);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    // Main getters to use for UI
    function getCollateralAssetList() external view returns (address[] memory) {
        PoolDataStorage storage $ = _getPoolDataStorage();
        return $._pool.getCollateralAssetList();
    }

    function getDebtAssetList() external view returns (address[] memory) {
        PoolDataStorage storage $ = _getPoolDataStorage();
        return $._pool.getDebtAssetList();
    }

    function getAssetData(
        address asset
    ) external view returns (AssetData memory) {
        PoolDataStorage storage $ = _getPoolDataStorage();
        AssetData memory assetData;
        assetData.assetType = $._pool.getAssetType(asset);
        if (assetData.assetType == IPool.AssetType.Collateral) {
            IPool.CollateralConfiguration memory config = $
                ._pool
                .getCollateralAssetConfiguration(asset);
            assetData.colToken = config.colToken;
            // No debtToken
            assetData.tokenVault = config.tokenVault;
            assetData.supplyCap = config.supplyCap;
            assetData.borrowCap = config.borrowCap;
            assetData.totalSupply = IERC20(assetData.colToken).totalSupply();
            // No totalBorrow
            // No totalShares
            // No utilizationRate
            // No supplyRate
            // No borrowRate
            assetData.ltv = config.ltv;
            assetData.liquidationThreshold = config.liquidationThreshold;
            assetData.liquidationBonus = config.liquidationBonus;
            assetData.liquidationProtocolFee = config.liquidationProtocolFee;
            assetData.reserveFactor = config.reserveFactor;
            assetData.decimals = IERC20Metadata(asset).decimals();
            assetData.isFrozen = config.isFrozen;
            assetData.isPaused = config.isPaused;
            // TODO add stakedTokens data
            assetData.stakedTokens = new StakedTokenData[](0);
        } else if (assetData.assetType == IPool.AssetType.Debt) {
            IPool.DebtConfiguration memory config = $
                ._pool
                .getDebtAssetConfiguration(asset);
            assetData.colToken = config.colToken;
            assetData.debtToken = config.debtToken;
            // No tokenVault
            assetData.supplyCap = config.supplyCap;
            assetData.borrowCap = config.borrowCap;
            assetData.totalBorrow = IERC20(assetData.debtToken).totalSupply();
            assetData.totalSupply =
                assetData.totalBorrow +
                IERC20(asset).balanceOf(assetData.colToken);
            assetData.totalShares = IERC20(assetData.colToken).totalSupply();
            assetData.utilizationRate =
                assetData.totalBorrow /
                assetData.totalSupply;
            // TODO supplyRate is necessary?
            // TODO borrowRate is necessary?
            assetData.reserveFactor = config.reserveFactor;
            assetData.decimals = IERC20Metadata(asset).decimals();
            assetData.isFrozen = config.isFrozen;
            assetData.isPaused = config.isPaused;
        }
        return assetData;
    }

    function getUserData(address user) external view returns (UserData memory) {
        PoolDataStorage storage $ = _getPoolDataStorage();
        UserData memory userData;
        IPool.UserAccountData memory userAccountData = $
            ._pool
            .getUserAccountData(user);
        userData.totalCollateralValue = userAccountData.totalCollateralValue;
        userData.totalDebtValue = userAccountData.totalDebtValue;
        userData.availableBorrowsValue = userAccountData.availableBorrowsValue;
        userData.currentLiquidationThreshold = userAccountData
            .currentLiquidationThreshold;
        userData.ltv = userAccountData.ltv;
        userData.healthFactor = userAccountData.healthFactor;

        address[] memory collaterals = $._pool.getCollateralAssetList();
        address[] memory debts = $._pool.getDebtAssetList();
        userData.userCollateralData = new UserCollateralData[](
            collaterals.length
        );
        userData.userDebtData = new UserDebtData[](debts.length);

        for (uint256 i; i < collaterals.length; i++) {
            IPool.CollateralConfiguration memory config = $
                ._pool
                .getCollateralAssetConfiguration(collaterals[i]);

            userData.userCollateralData[i] = UserCollateralData(
                collaterals[i],
                IERC20(config.colToken).balanceOf(user)
            );
        }
        for (uint256 i; i < debts.length; i++) {
            IPool.DebtConfiguration memory config = $
                ._pool
                .getDebtAssetConfiguration(debts[i]);
            IERC4626 colToken = IERC4626(config.colToken);

            userData.userDebtData[i] = UserDebtData(
                debts[i],
                colToken.convertToAssets(colToken.balanceOf(user)), // supplyBalance: shares => assets
                IERC20(config.debtToken).balanceOf(user)
            );
        }
        return userData;
    }

    function getCollateralAssetConfiguration(
        address collateralAsset
    ) external view returns (IPool.CollateralConfiguration memory) {
        PoolDataStorage storage $ = _getPoolDataStorage();
        return $._pool.getCollateralAssetConfiguration(collateralAsset);
    }

    function getCollateralAssetsConfiguration(
        address[] memory collateralAssets
    ) external view returns (IPool.CollateralConfiguration[] memory) {
        PoolDataStorage storage $ = _getPoolDataStorage();
        uint256 length = collateralAssets.length;
        IPool.CollateralConfiguration[]
            memory configs = new IPool.CollateralConfiguration[](length);
        for (uint256 i; i < length; i++) {
            configs[i] = $._pool.getCollateralAssetConfiguration(
                collateralAssets[i]
            );
        }
        return configs;
    }

    function getDebtAssetConfiguration(
        address debtAsset
    ) external view returns (IPool.DebtConfiguration memory) {
        PoolDataStorage storage $ = _getPoolDataStorage();
        return $._pool.getDebtAssetConfiguration(debtAsset);
    }

    function getDebtAssetsConfiguration(
        address[] memory debtAssets
    ) external view returns (IPool.DebtConfiguration[] memory) {
        PoolDataStorage storage $ = _getPoolDataStorage();
        uint256 length = debtAssets.length;
        IPool.DebtConfiguration[]
            memory configs = new IPool.DebtConfiguration[](length);
        for (uint256 i; i < length; i++) {
            configs[i] = $._pool.getDebtAssetConfiguration(debtAssets[i]);
        }
        return configs;
    }
}
