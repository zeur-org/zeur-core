// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {HEALTH_FACTOR_BASE} from "../helpers/Constants.sol";
import {IColToken} from "../interfaces/tokenization/IColToken.sol";
import {IDebtEUR} from "../interfaces/tokenization/IDebtEUR.sol";
import {IColEUR} from "../interfaces/tokenization/IColEUR.sol";
import {IPool} from "../interfaces/pool/IPool.sol";
import {IVault} from "../interfaces/vault/IVault.sol";
import {IChainlinkOracleManager} from "../interfaces/chainlink/IChainlinkOracleManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Pool is
    Initializable,
    AccessManagedUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IPool
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    address private constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct PoolStorage {
        IChainlinkOracleManager _oracleManager;
        EnumerableSet.AddressSet _collateralAssetList;
        EnumerableSet.AddressSet _debtAssetList;
        mapping(address => CollateralConfiguration) _collateralConfigurations;
        mapping(address => DebtConfiguration) _debtConfigurations;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.Pool")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PoolStorageLocation =
        0xf6dc39a5b94a19ce9779ff0edd3e99689c64f6f147904be9be82d2db712c7600;

    function _getPoolStorage() private pure returns (PoolStorage storage $) {
        assembly {
            $.slot := PoolStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        address oracleManager
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        PoolStorage storage $ = _getPoolStorage();
        $._oracleManager = IChainlinkOracleManager(oracleManager);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function supply(
        address asset,
        uint256 amount,
        address from
    ) external payable {
        PoolStorage storage $ = _getPoolStorage();

        IERC20 assetToken = IERC20(asset);

        // If asset is collateral asset (ETH or LINK)
        if ($._collateralAssetList.contains(asset)) {
            CollateralConfiguration memory configuration = $
                ._collateralConfigurations[asset];
            _validateCollateral(configuration, amount, UserAction.Supply);

            IColToken colToken = IColToken(configuration.colToken);
            IVault tokenVault = IVault(configuration.tokenVault);

            if (asset == ETH_ADDRESS) {
                // Lock ETH into the vault
                if (msg.value != amount) revert Pool_InvalidAmount();
                tokenVault.lockCollateral{value: amount}(from, amount);

                // Mint colETH to the user
                colToken.mint(from, amount);
            } else {
                // Transfer the asset from the user to the pool
                // Call lockCollateral to trigger staking function in vault
                IERC20(asset).safeTransferFrom(
                    from,
                    address(tokenVault),
                    amount
                );
                tokenVault.lockCollateral(from, amount);

                // Mint colToken to the user
                colToken.mint(from, amount);
            }
        } else if ($._debtAssetList.contains(asset)) {
            // If asset is borrowable asset (EUR)
            DebtConfiguration memory configuration = $._debtConfigurations[
                asset
            ];
            _validateDebt(configuration, asset, amount, UserAction.Supply);

            assetToken.safeTransferFrom(from, address(this), amount);
            assetToken.approve(configuration.colToken, amount);

            // Deposit EUR to ERC4626 colEUR => mint directly shares to from address
            IColEUR colEUR = IColEUR(configuration.colToken);
            colEUR.deposit(amount, from);
        } else {
            revert Pool_AssetNotAllowed(asset);
        }
    }

    function withdraw(address asset, uint256 amount, address to) external {
        PoolStorage storage $ = _getPoolStorage();

        if ($._collateralAssetList.contains(asset)) {
            CollateralConfiguration memory configuration = $
                ._collateralConfigurations[asset];
            _validateCollateral(configuration, amount, UserAction.Withdraw);

            IColToken colToken = IColToken(configuration.colToken);

            // Burn colToken from msg.sender
            colToken.burn(msg.sender, amount);

            // Unlock collateral from vault
            IVault tokenVault = IVault(configuration.tokenVault);
            if (asset == ETH_ADDRESS) {
                tokenVault.unlockCollateral(to, amount);
            } else {}

            // Transfer collateral back to user
        } else if ($._debtAssetList.contains(asset)) {} else {
            revert Pool_AssetNotAllowed(asset);
        }

        // TODO: Check HF of msg.sender after withdraw
        UserAccountData memory userAccountData = getUserAccountData(msg.sender);
        if (userAccountData.healthFactor < HEALTH_FACTOR_BASE)
            revert Pool_InsufficientHealthFactor();

        emit Withdraw(asset, amount, to, msg.sender);
    }

    function borrow(
        address asset,
        uint256 amount,
        address to
    ) external override {
        PoolStorage storage $ = _getPoolStorage();
        if (!$._collateralAssetList.contains(asset))
            revert Pool_AssetNotAllowed(asset);

        DebtConfiguration memory configuration = $._debtConfigurations[asset];
        _validateDebt(configuration, asset, amount, UserAction.Borrow);

        // Check availableBorrowsValue of msg.sender
        // Get value of asset amount to be borrowed
        uint256 assetValue = ($._oracleManager.getAssetPrice(asset) * amount) /
            10 ** IERC20Metadata(asset).decimals();

        UserAccountData memory userAccountData = getUserAccountData(msg.sender);

        // Check if availableBorrowsValue is enough
        if (userAccountData.availableBorrowsValue < assetValue)
            revert Pool_InsufficientAvailableBorrowsValue();

        // Mint debtEUR to msg.sender
        IDebtEUR debtEUR = IDebtEUR(configuration.debtToken);
        debtEUR.mint(msg.sender, amount);

        // Transfer EUR from colEUR to "to" address
        IERC20(asset).safeTransferFrom(configuration.colToken, to, amount);
    }

    function repay(
        address asset,
        uint256 amount,
        address from
    ) external override {
        PoolStorage storage $ = _getPoolStorage();
        if (!$._debtAssetList.contains(asset))
            revert Pool_AssetNotAllowed(asset);

        DebtConfiguration memory configuration = $._debtConfigurations[asset];
        _validateDebt(configuration, asset, amount, UserAction.Repay);

        IERC20 assetToken = IERC20(asset);
        IDebtEUR debtToken = IDebtEUR(configuration.debtToken);

        // Transfer asset from msg.sender to colToken
        assetToken.safeTransferFrom(msg.sender, configuration.colToken, amount);

        // Burn the corresponding debtToken of "from" balance
        debtToken.burn(from, amount);

        emit Repay(asset, amount, from, msg.sender);
    }

    function liquidate(
        address collateralAsset,
        address debtAsset,
        uint256 debtAmount,
        address from
    ) external {}

    function initCollateralAsset(
        address collateralAsset,
        CollateralConfiguration memory collateralConfiguration
    ) external override restricted {
        PoolStorage storage $ = _getPoolStorage();
        if (
            $._collateralAssetList.contains(collateralAsset) ||
            $._debtAssetList.contains(collateralAsset)
        ) revert Pool_AssetAlreadyInitialized(collateralAsset);

        $._collateralAssetList.add(collateralAsset);
        $._collateralConfigurations[collateralAsset] = collateralConfiguration;

        emit InitCollateralAsset(collateralAsset, collateralConfiguration);
    }

    function initDebtAsset(
        address debtAsset,
        DebtConfiguration memory debtConfiguration
    ) external override restricted {
        PoolStorage storage $ = _getPoolStorage();
        if (
            $._debtAssetList.contains(debtAsset) ||
            $._collateralAssetList.contains(debtAsset)
        ) revert Pool_AssetAlreadyInitialized(debtAsset);

        $._debtAssetList.add(debtAsset);
        $._debtConfigurations[debtAsset] = debtConfiguration;

        emit InitDebtAsset(debtAsset, debtConfiguration);
    }

    function setCollateralConfiguration(
        address collateralAsset,
        CollateralConfiguration memory collateralConfiguration
    ) external override restricted {
        PoolStorage storage $ = _getPoolStorage();
        if (!$._collateralAssetList.contains(collateralAsset))
            revert Pool_AssetNotAllowed(collateralAsset);

        $._collateralConfigurations[collateralAsset] = collateralConfiguration;

        emit SetCollateralConfiguration(
            collateralAsset,
            collateralConfiguration
        );
    }

    function setDebtConfiguration(
        address debtAsset,
        DebtConfiguration memory debtConfiguration
    ) external override restricted {
        PoolStorage storage $ = _getPoolStorage();
        if (!$._debtAssetList.contains(debtAsset))
            revert Pool_AssetNotAllowed(debtAsset);

        $._debtConfigurations[debtAsset] = debtConfiguration;

        emit SetDebtConfiguration(debtAsset, debtConfiguration);
    }

    function getCollateralAssetList()
        external
        view
        override
        returns (address[] memory)
    {
        PoolStorage storage $ = _getPoolStorage();
        return $._collateralAssetList.values();
    }

    function getDebtAssetList()
        external
        view
        override
        returns (address[] memory)
    {
        PoolStorage storage $ = _getPoolStorage();
        return $._debtAssetList.values();
    }

    function getCollateralAssetConfiguration(
        address collateralAsset
    ) external view override returns (CollateralConfiguration memory) {
        PoolStorage storage $ = _getPoolStorage();
        return $._collateralConfigurations[collateralAsset];
    }

    function getDebtAssetConfiguration(
        address debtAsset
    ) external view override returns (DebtConfiguration memory) {
        PoolStorage storage $ = _getPoolStorage();
        return $._debtConfigurations[debtAsset];
    }

    function getUserAccountData(
        address user
    ) public view override returns (UserAccountData memory userAccountData) {
        PoolStorage storage $ = _getPoolStorage();

        address[] memory collateralAssets = $._collateralAssetList.values();
        address[] memory debtAssets = $._debtAssetList.values();

        uint256 collateralLength = collateralAssets.length;
        uint256 debtLength = debtAssets.length;
        UserCalculationData memory calculationData;

        for (uint256 i; i < collateralLength; i++) {
            calculationData.underlyingToken = collateralAssets[i];

            calculationData.tokenizedToken = IERC20Metadata(
                $
                    ._collateralConfigurations[calculationData.underlyingToken]
                    .colToken
            );

            // Calculate collateral value of the individual token in base currency (USD in 8 decimals, following Chainlink)
            calculationData.collateralValue =
                (calculationData.tokenizedToken.balanceOf(user) *
                    $._oracleManager.getAssetPrice(
                        calculationData.underlyingToken
                    )) /
                10 ** calculationData.tokenizedToken.decimals();

            // Calculate borrowable value in base currency (USD in 8 decimals, following Chainlink)
            calculationData.totalBorrowableValue +=
                (calculationData.collateralValue *
                    $
                        ._collateralConfigurations[
                            calculationData.underlyingToken
                        ]
                        .ltv) /
                10000;

            // Calculate collateral value in base currency (USD in 8 decimals, following Chainlink)
            userAccountData.totalCollateralValue += calculationData
                .collateralValue;
        }

        for (uint256 i; i < debtLength; i++) {
            calculationData.underlyingToken = debtAssets[i];
            calculationData.tokenizedToken = IERC20Metadata(
                $._debtConfigurations[calculationData.underlyingToken].debtToken
            );

            // Calculate debt value in base currency (USD in 8 decimals, following Chainlink)
            userAccountData.totalDebtValue +=
                (calculationData.tokenizedToken.balanceOf(user) *
                    $._oracleManager.getAssetPrice(
                        calculationData.underlyingToken
                    )) /
                10 ** calculationData.tokenizedToken.decimals();
        }

        userAccountData.availableBorrowsValue =
            calculationData.totalBorrowableValue -
            userAccountData.totalDebtValue;

        // TODO: Calculate current liquidation threshold, ltv, healthFactor
    }

    function _validateCollateral(
        CollateralConfiguration memory configuration,
        uint256 amount,
        UserAction action
    ) private view {
        if (amount == 0) revert Pool_InvalidAmount();

        // Can not do anything when collateral paused
        if (configuration.isPaused) revert Pool_CollateralPaused();

        if (action == UserAction.Supply) {
            // Can not supply when collateral frozen
            if (configuration.isFrozen) revert Pool_CollateralFrozen();

            // Total colToken of collateral + new amount must <= supplyCap
            if (
                IERC20(configuration.colToken).totalSupply() + amount >
                configuration.supplyCap
            ) revert Pool_SupplyCapExceeded();
        }
    }

    function _validateDebt(
        DebtConfiguration memory configuration,
        address asset,
        uint256 amount,
        UserAction action
    ) private view {
        if (amount == 0) revert Pool_InvalidAmount();

        // Can not do anything when asset paused
        if (configuration.isPaused) revert Pool_DebtPaused();

        // Can not supply/borrow when asset frozen
        if (
            configuration.isFrozen &&
            (action == UserAction.Supply || action == UserAction.Borrow)
        ) revert Pool_DebtFrozen();

        if (action == UserAction.Supply) {
            if (
                // Total EUR borrowed + EUR stored in colEUR + new supply must <= supplyCap
                IERC20(configuration.debtToken).totalSupply() +
                    IERC20(asset).balanceOf(configuration.colToken) +
                    amount >
                configuration.supplyCap
            ) revert Pool_SupplyCapExceeded();
        }
    }

    function _validateBorrow() private view {}

    function _validateRepay() private view {}

    function _validateLiquidate() private view {}
}
