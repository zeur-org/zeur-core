// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPool} from "../interfaces/pool/IPool.sol";
import {IPoolData} from "../interfaces/pool/IPoolData.sol";
import {IChainlinkOracleManager} from "../interfaces/chainlink/IChainlinkOracleManager.sol";
import {IVault} from "../interfaces/vault/IVault.sol";
import {IStakingRouter} from "../interfaces/router/IStakingRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

    function getCollateralStakingData(
        address collateralAsset
    )
        external
        view
        returns (
            address[] memory stakedTokens,
            uint256[] memory stakedAmounts,
            uint256[] memory underlyingAmounts
        )
    {
        PoolDataStorage storage $ = _getPoolDataStorage();
        IPool.CollateralConfiguration memory configuration = $
            ._pool
            .getCollateralAssetConfiguration(collateralAsset);

        IVault vault = IVault(configuration.tokenVault);
        address[] memory stakingRouters = vault.getStakingRouters();
        uint256 length = stakingRouters.length;

        stakedTokens = new address[](length);
        stakedAmounts = new uint256[](length);
        underlyingAmounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            IERC20 stakedToken = IERC20(
                IStakingRouter(stakingRouters[i]).getStakedToken()
            );
            uint256 stakedAmount = stakedToken.balanceOf(address(vault));
            stakedTokens[i] = address(stakedToken);
            stakedAmounts[i] = stakedAmount;
            underlyingAmounts[i] = IStakingRouter(stakingRouters[i])
                .getTotalStakedUnderlying();
        }

        return (stakedTokens, stakedAmounts, underlyingAmounts);
    }

    function getDebtData(
        address debtAsset
    )
        external
        view
        returns (
            address[] memory stakedTokens,
            uint256[] memory stakedAmounts,
            uint256[] memory underlyingAmounts
        )
    {
        PoolDataStorage storage $ = _getPoolDataStorage();
        IPool.DebtConfiguration memory configuration = $
            ._pool
            .getDebtAssetConfiguration(debtAsset);
    }

    function getAllCollateralData()
        external
        view
        returns (CollateralData[] memory collateralDatas)
    {
        PoolDataStorage storage $ = _getPoolDataStorage();
        address[] memory collateralAssets = $._pool.getCollateralAssetList();
        uint256 length = collateralAssets.length;
        collateralDatas = new CollateralData[](length);

        for (uint256 i = 0; i < length; i++) {
            IPool.CollateralConfiguration memory configuration = $
                ._pool
                .getCollateralAssetConfiguration(collateralAssets[i]);
            collateralDatas[i].collateralAsset = collateralAssets[i];

            IVault vault = IVault(configuration.tokenVault);
            address[] memory stakingRouters = vault.getStakingRouters();
            uint256 stakingLength = stakingRouters.length;

            collateralDatas[i].stakedTokens = new address[](stakingLength);
            collateralDatas[i].stakedAmounts = new uint256[](stakingLength);
            collateralDatas[i].underlyingAmounts = new uint256[](stakingLength);

            for (uint256 j = 0; j < stakingLength; j++) {
                IERC20 stakedToken = IERC20(
                    IStakingRouter(stakingRouters[j]).getStakedToken()
                );
                collateralDatas[i].stakedTokens[j] = address(stakedToken);
                collateralDatas[i].stakedAmounts[j] = stakedToken.balanceOf(
                    address(vault)
                );
                collateralDatas[i].underlyingAmounts[j] = IStakingRouter(
                    stakingRouters[j]
                ).getTotalStakedUnderlying();
            }
        }

        return collateralDatas;
    }

    function getAllDebtData()
        external
        view
        returns (DebtData[] memory debtDatas)
    {
        PoolDataStorage storage $ = _getPoolDataStorage();
        address[] memory debtAssets = $._pool.getDebtAssetList();
        uint256 length = debtAssets.length;
        debtDatas = new DebtData[](length);

        for (uint256 i = 0; i < length; i++) {
            IPool.DebtConfiguration memory configuration = $
                ._pool
                .getDebtAssetConfiguration(debtAssets[i]);
            debtDatas[i].debtAsset = debtAssets[i];

            debtDatas[i].suppliedAmount = IERC20(configuration.colToken)
                .totalSupply();
            debtDatas[i].borrowedAmount = IERC20(configuration.debtToken)
                .totalSupply();
        }

        return debtDatas;
    }
}
