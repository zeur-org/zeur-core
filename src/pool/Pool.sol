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
    ) external payable nonReentrant {
        PoolStorage storage $ = _getPoolStorage();

        IERC20 assetToken = IERC20(asset);

        // If asset is collateral asset (ETH or LINK)
        if ($._collateralAssetList.contains(asset)) {
            CollateralConfiguration memory configuration = $
                ._collateralConfigurations[asset];
            _validateCollateralAsset(
                asset,
                amount,
                UserAction.Supply,
                configuration
            );

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
            _validateDebtAsset(asset, amount, UserAction.Supply, configuration);

            assetToken.safeTransferFrom(from, address(this), amount);
            assetToken.forceApprove(configuration.colToken, amount);

            // Deposit EUR to ERC4626 colEUR => mint directly shares to from address
            IColEUR colEUR = IColEUR(configuration.colToken);
            colEUR.deposit(amount, from);
        } else {
            revert Pool_AssetNotAllowed(asset);
        }
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external nonReentrant {
        PoolStorage storage $ = _getPoolStorage();

        if ($._collateralAssetList.contains(asset)) {
            CollateralConfiguration memory configuration = $
                ._collateralConfigurations[asset];
            _validateCollateralAsset(
                asset,
                amount,
                UserAction.Withdraw,
                configuration
            );

            IColToken colToken = IColToken(configuration.colToken);

            // Burn colToken from msg.sender
            colToken.burn(msg.sender, amount);

            // Unlock collateral from vault
            IVault tokenVault = IVault(configuration.tokenVault);
            tokenVault.unlockCollateral(to, amount); // Unlock process is the same for ETH and LINK
            // if (asset == ETH_ADDRESS) {
            //     tokenVault.unlockCollateral(to, amount);
            // } else {
            //     // TODO: unlockCollateral for ERC20
            // }

            // Transfer collateral back to user
        } else if ($._debtAssetList.contains(asset)) {
            DebtConfiguration memory configuration = $._debtConfigurations[
                asset
            ];
            _validateDebtAsset(
                asset,
                amount,
                UserAction.Withdraw,
                configuration
            );

            // Withdraw from colEUR
            IColEUR colEUR = IColEUR(configuration.colToken);
            colEUR.withdraw(amount, to, msg.sender);
        } else {
            revert Pool_AssetNotAllowed(asset);
        }

        // TODO: Check HF of msg.sender after withdraw
        UserAccountData memory userAccountData = _getUserAccountData(
            msg.sender,
            $
        );
        if (userAccountData.healthFactor < HEALTH_FACTOR_BASE)
            revert Pool_InsufficientHealthFactor();

        emit Withdraw(asset, amount, to, msg.sender);
    }

    function borrow(
        address asset,
        uint256 amount,
        address to
    ) external override nonReentrant {
        PoolStorage storage $ = _getPoolStorage();
        if (!$._debtAssetList.contains(asset))
            revert Pool_AssetNotAllowed(asset);

        DebtConfiguration memory configuration = $._debtConfigurations[asset];
        _validateDebtAsset(asset, amount, UserAction.Borrow, configuration);

        // Check availableBorrowsValue of msg.sender
        // Get value of asset amount to be borrowed
        uint256 assetValue = ($._oracleManager.getAssetPrice(asset) * amount) /
            10 ** IERC20Metadata(asset).decimals();

        UserAccountData memory userAccountData = _getUserAccountData(
            msg.sender,
            $
        );

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
    ) external override nonReentrant {
        PoolStorage storage $ = _getPoolStorage();
        if (!$._debtAssetList.contains(asset))
            revert Pool_AssetNotAllowed(asset);

        DebtConfiguration memory configuration = $._debtConfigurations[asset];
        _validateDebtAsset(asset, amount, UserAction.Repay, configuration);

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
    ) external nonReentrant {
        // TODO: implement logics
        // Calculate health factor
        // Verify liquidation conditions
        // Execute liquidation with proper incentives
        // Update user positions
    }

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
    ) external view override returns (UserAccountData memory userAccountData) {
        PoolStorage storage $ = _getPoolStorage();
        userAccountData = _getUserAccountData(user, $);
    }

    function _getUserAccountData(
        address user,
        PoolStorage storage $
    ) private view returns (UserAccountData memory userAccountData) {
        UserCalculationData memory cache;

        cache.oracleManager = $._oracleManager;
        cache.collateralAssets = $._collateralAssetList.values();
        cache.debtAssets = $._debtAssetList.values();
        cache.collateralLength = uint16(cache.collateralAssets.length);
        cache.debtLength = uint16(cache.debtAssets.length);

        // Loop through all user's collaterals to calculate total collateral value and total borrowable value (based on ltv)
        for (uint256 i; i < cache.collateralLength; i++) {
            cache.cacheAsset = cache.collateralAssets[i];

            cache.cacheTokenizedAsset = IERC20Metadata(
                $._collateralConfigurations[cache.cacheAsset].colToken
            );

            // Calculate collateral value of the individual token in base currency (USD in 8 decimals, following Chainlink)
            cache.collateralValue =
                (cache.cacheTokenizedAsset.balanceOf(user) *
                    cache.oracleManager.getAssetPrice(cache.cacheAsset)) /
                10 ** cache.cacheTokenizedAsset.decimals();

            // Calculate borrowable value in base currency (USD in 8 decimals, following Chainlink)
            cache.totalBorrowableValue +=
                (cache.collateralValue *
                    $._collateralConfigurations[cache.cacheAsset].ltv) /
                10000;

            // Calculate collateral value in base currency (USD in 8 decimals, following Chainlink)
            userAccountData.totalCollateralValue += cache.collateralValue;
        }

        // Loop through all user's debts to calculate total debt value
        for (uint256 i; i < cache.debtLength; i++) {
            cache.cacheAsset = cache.debtAssets[i];
            cache.cacheTokenizedAsset = IERC20Metadata(
                $._debtConfigurations[cache.cacheAsset].debtToken
            );

            // Calculate debt value in base currency (USD in 8 decimals, following Chainlink)
            userAccountData.totalDebtValue +=
                (cache.cacheTokenizedAsset.balanceOf(user) *
                    cache.oracleManager.getAssetPrice(cache.cacheAsset)) /
                10 ** cache.cacheTokenizedAsset.decimals();
        }

        userAccountData.availableBorrowsValue =
            cache.totalBorrowableValue -
            userAccountData.totalDebtValue;

        // Calculate current liquidation threshold (weighted average)
        if (userAccountData.totalCollateralValue > 0) {
            uint256 weightedLiquidationThreshold = 0;

            // Loop through collateral assets again to calculate weighted liquidation threshold
            for (uint256 i; i < cache.collateralLength; i++) {
                cache.cacheAsset = cache.collateralAssets[i];
                cache.cacheTokenizedAsset = IERC20Metadata(
                    $._collateralConfigurations[cache.cacheAsset].colToken
                );

                // Calculate collateral value of the individual token
                cache.collateralValue =
                    (cache.cacheTokenizedAsset.balanceOf(user) *
                        cache.oracleManager.getAssetPrice(cache.cacheAsset)) /
                    10 ** cache.cacheTokenizedAsset.decimals();

                // Add weighted liquidation threshold
                weightedLiquidationThreshold +=
                    (cache.collateralValue *
                        $
                            ._collateralConfigurations[cache.cacheAsset]
                            .liquidationThreshold) /
                    userAccountData.totalCollateralValue;
            }

            userAccountData
                .currentLiquidationThreshold = weightedLiquidationThreshold;
        }

        // Calculate LTV (loan-to-value ratio)
        if (userAccountData.totalCollateralValue > 0) {
            userAccountData.ltv =
                (userAccountData.totalDebtValue * 10000) /
                userAccountData.totalCollateralValue;
        }

        // Calculate health factor
        if (userAccountData.totalDebtValue > 0) {
            userAccountData.healthFactor =
                (userAccountData.totalCollateralValue *
                    userAccountData.currentLiquidationThreshold) /
                (userAccountData.totalDebtValue * 10000);
        } else {
            // If no debt, health factor is at maximum (representing infinite health)
            userAccountData.healthFactor = type(uint256).max;
        }
    }

    function _validateCollateralAsset(
        address asset,
        uint256 amount,
        UserAction action,
        CollateralConfiguration memory configuration
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

    function _validateDebtAsset(
        address asset,
        uint256 amount,
        UserAction action,
        DebtConfiguration memory configuration
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

        if (action == UserAction.Borrow) {
            if (
                // Total EUR borrowed + new borrow must <= borrowCap
                IERC20(configuration.debtToken).totalSupply() + amount >
                configuration.borrowCap
            ) revert Pool_BorrowCapExceeded();
        }
    }
}
