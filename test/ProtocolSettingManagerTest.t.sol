// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ProtocolSettingManager} from "../src/pool/manager/ProtocolSettingManager.sol";
import {ProtocolSettingManagerV2} from "./mock/ProtocolSettingManagerV2.sol";
import {TestSetupLocalHelpers} from "./TestSetupLocalHelpers.s.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {INITIAL_ADMIN, SETTING_MANAGER_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";
import {ColToken} from "../src/pool/tokenization/ColToken.sol";
import {IPool} from "../src/interfaces/pool/IPool.sol";
import {Pool} from "../src/pool/Pool.sol";

contract ProtocolSettingManagerTest is Test {
    ProtocolSettingManager private settingManager;
    ColToken private colETH;
    Pool private pool;

    address public settingManagerAdmin = SETTING_MANAGER_ADMIN;
    address newCollateral = makeAddr("newCollateral");
    address newDebt = makeAddr("newDebt");

    address colTokenAddress = makeAddr("colTokenAddress");
    address debtTokenAddress = makeAddr("debtTokenAddress");
    address vaultAddress = makeAddr("vaultAddress");

    address newColTokenAddress = makeAddr("newColTokenAddress");
    address newDebtTokenAddress = makeAddr("newDebtTokenAddress");
    address newTokenVaultAddress = makeAddr("newTokenVaultAddress");

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public initialAdmin = INITIAL_ADMIN;

    IPool.CollateralConfiguration collateralConfig;
    IPool.CollateralConfiguration newCollateralConfig;
    IPool.DebtConfiguration debtConfig;
    IPool.DebtConfiguration newDebtConfig;

    uint256 collateralSupplyCap = 10000e18;
    uint256 collateralBorrowCap = 8000e18;
    uint16 collateralLtv = 8000;
    uint16 collateralLiquidationThreshold = 8500;
    uint16 collateralLiquidationBonus = 500;
    uint16 collateralLiquidationProtocolFee = 1000;
    uint16 collateralReserveFactor = 1000;

    uint256 newCollateralSupplyCap = 20000e18;
    uint256 newCollateralBorrowCap = 16000e18;
    uint16 newCollateralLtv = 7000;
    uint16 newCollateralLiquidationThreshold = 7500;
    uint16 newCollateralLiquidationBonus = 1000;
    uint16 newCollateralLiquidationProtocolFee = 1500;
    uint16 newCollateralReserveFactor = 1500;

    uint256 debtSupplyCap = 1000000e6;
    uint256 debtBorrowCap = 800000e6;
    uint16 debtReserveFactor = 1000;

    uint256 newDebtSupplyCap = 2000000e6;
    uint256 newDebtBorrowCap = 1600000e6;
    uint16 newDebtReserveFactor = 1500;

    function setUp() public {
        TestSetupLocalHelpers setup = new TestSetupLocalHelpers();

        (
            TestSetupLocalHelpers.CoreContracts memory coreContracts,
            TestSetupLocalHelpers.TokenizationContracts
                memory tokenizationContracts,
            TestSetupLocalHelpers.VaultContracts memory vaultContracts,
            TestSetupLocalHelpers.StakingRouters memory stakingRouters,
            TestSetupLocalHelpers.MockContracts memory mockContracts
        ) = setup.deployAll();

        settingManager = coreContracts.settingManager;
        colETH = tokenizationContracts.colETH;
        pool = coreContracts.pool;

        collateralConfig = IPool.CollateralConfiguration({
            supplyCap: collateralSupplyCap,
            borrowCap: collateralBorrowCap,
            colToken: colTokenAddress,
            tokenVault: vaultAddress,
            ltv: collateralLtv,
            liquidationThreshold: collateralLiquidationThreshold,
            liquidationBonus: collateralLiquidationBonus,
            liquidationProtocolFee: collateralLiquidationProtocolFee,
            reserveFactor: collateralReserveFactor,
            isFrozen: false,
            isPaused: false
        });

        newCollateralConfig = IPool.CollateralConfiguration({
            supplyCap: newCollateralSupplyCap,
            borrowCap: newCollateralBorrowCap,
            colToken: newColTokenAddress,
            tokenVault: newTokenVaultAddress,
            ltv: newCollateralLtv,
            liquidationThreshold: newCollateralLiquidationThreshold,
            liquidationBonus: newCollateralLiquidationBonus,
            liquidationProtocolFee: newCollateralLiquidationProtocolFee,
            reserveFactor: newCollateralReserveFactor,
            isFrozen: false,
            isPaused: false
        });

        debtConfig = IPool.DebtConfiguration({
            supplyCap: debtSupplyCap,
            borrowCap: debtBorrowCap,
            colToken: colTokenAddress,
            debtToken: debtTokenAddress,
            reserveFactor: debtReserveFactor,
            isFrozen: false,
            isPaused: false
        });

        newDebtConfig = IPool.DebtConfiguration({
            supplyCap: newDebtSupplyCap,
            borrowCap: newDebtBorrowCap,
            colToken: newColTokenAddress,
            debtToken: newDebtTokenAddress,
            reserveFactor: newDebtReserveFactor,
            isFrozen: false,
            isPaused: false
        });
    }

    function _setUpAssets() public {
        vm.startPrank(settingManagerAdmin);
        settingManager.initCollateralAsset(newCollateral, collateralConfig);
        settingManager.initDebtAsset(newDebt, debtConfig);
        vm.stopPrank();
    }

    function test_initCollateralAsset() public {
        vm.startPrank(settingManagerAdmin);

        vm.expectEmit(true, false, false, true);
        emit IPool.InitCollateralAsset(newCollateral, collateralConfig);
        settingManager.initCollateralAsset(newCollateral, collateralConfig);

        address[] memory collateralAssets = pool.getCollateralAssetList();
        assertEq(collateralAssets.length, 3);
        assertEq(collateralAssets[2], newCollateral);

        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(newCollateral);

        assertEq(storedConfig.supplyCap, collateralSupplyCap);
        assertEq(storedConfig.colToken, colTokenAddress);
        assertEq(storedConfig.tokenVault, vaultAddress);
        assertEq(storedConfig.ltv, collateralLtv);
        assertEq(
            storedConfig.liquidationThreshold,
            collateralLiquidationThreshold
        );
        assertEq(storedConfig.liquidationBonus, collateralLiquidationBonus);
        assertEq(
            storedConfig.liquidationProtocolFee,
            collateralLiquidationProtocolFee
        );
        assertEq(storedConfig.reserveFactor, collateralReserveFactor);
        assertEq(storedConfig.isFrozen, false);
        assertEq(storedConfig.isPaused, false);

        vm.stopPrank();
    }

    function test_initDebtAsset() public {
        vm.startPrank(settingManagerAdmin);

        vm.expectEmit(true, false, false, true);
        emit IPool.InitDebtAsset(newDebt, debtConfig);
        settingManager.initDebtAsset(newDebt, debtConfig);

        // Verify asset is added to list
        address[] memory debtAssets = pool.getDebtAssetList();
        assertEq(debtAssets.length, 2);
        assertEq(debtAssets[1], newDebt);

        // Verify configuration
        IPool.DebtConfiguration memory storedConfig = pool
            .getDebtAssetConfiguration(newDebt);

        assertEq(storedConfig.supplyCap, debtSupplyCap);
        assertEq(storedConfig.colToken, colTokenAddress);
        assertEq(storedConfig.debtToken, debtTokenAddress);
        assertEq(storedConfig.reserveFactor, debtReserveFactor);
        assertEq(storedConfig.isFrozen, false);
        assertEq(storedConfig.isPaused, false);

        vm.stopPrank();
    }

    function test_setCollateralConfiguration() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);

        vm.expectEmit(true, false, false, true);
        emit IPool.SetCollateralConfiguration(
            newCollateral,
            newCollateralConfig
        );
        settingManager.setCollateralConfiguration(
            newCollateral,
            newCollateralConfig
        );

        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(newCollateral);

        assertEq(storedConfig.supplyCap, newCollateralSupplyCap);
        assertEq(storedConfig.colToken, newColTokenAddress);
        assertEq(storedConfig.tokenVault, newTokenVaultAddress);
        assertEq(storedConfig.ltv, newCollateralLtv);
        assertEq(
            storedConfig.liquidationThreshold,
            newCollateralLiquidationThreshold
        );
        assertEq(storedConfig.liquidationBonus, newCollateralLiquidationBonus);
        assertEq(
            storedConfig.liquidationProtocolFee,
            newCollateralLiquidationProtocolFee
        );
        assertEq(storedConfig.reserveFactor, newCollateralReserveFactor);
        assertEq(storedConfig.isFrozen, false);
        assertEq(storedConfig.isPaused, false);
    }

    function test_setCollateralLtv() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.setCollateralLtv(newCollateral, newCollateralLtv);

        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(newCollateral);
        assertEq(storedConfig.ltv, newCollateralLtv);

        vm.stopPrank();
    }

    function test_setCollateralLiquidationThreshold() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.setCollateralLiquidationThreshold(
            newCollateral,
            newCollateralLiquidationThreshold
        );

        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(newCollateral);
        assertEq(
            storedConfig.liquidationThreshold,
            newCollateralLiquidationThreshold
        );

        vm.stopPrank();
    }

    function test_setCollateralLiquidationBonus() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.setCollateralLiquidationBonus(
            newCollateral,
            newCollateralLiquidationBonus
        );

        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(newCollateral);
        assertEq(storedConfig.liquidationBonus, newCollateralLiquidationBonus);

        vm.stopPrank();
    }

    function test_setCollateralLiquidationProtocolFee() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.setCollateralLiquidationProtocolFee(
            newCollateral,
            newCollateralLiquidationProtocolFee
        );

        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(newCollateral);
        assertEq(
            storedConfig.liquidationProtocolFee,
            newCollateralLiquidationProtocolFee
        );

        vm.stopPrank();
    }

    function test_setCollateralReserveFactor() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.setCollateralReserveFactor(
            newCollateral,
            newCollateralReserveFactor
        );

        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(newCollateral);
        assertEq(storedConfig.reserveFactor, newCollateralReserveFactor);

        vm.stopPrank();
    }

    function test_setCollateralSupplyCap() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.setCollateralSupplyCap(
            newCollateral,
            newCollateralSupplyCap
        );

        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(newCollateral);
        assertEq(storedConfig.supplyCap, newCollateralSupplyCap);

        vm.stopPrank();
    }

    function test_setCollateralBorrowCap() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.setCollateralBorrowCap(
            newCollateral,
            newCollateralBorrowCap
        );

        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(newCollateral);
        assertEq(storedConfig.borrowCap, newCollateralBorrowCap);

        vm.stopPrank();
    }

    function test_setDebtConfiguration() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.setDebtConfiguration(newDebt, newDebtConfig);

        IPool.DebtConfiguration memory storedConfig = pool
            .getDebtAssetConfiguration(newDebt);
        assertEq(storedConfig.supplyCap, newDebtSupplyCap);
        assertEq(storedConfig.borrowCap, newDebtBorrowCap);
        assertEq(storedConfig.colToken, newColTokenAddress);
        assertEq(storedConfig.debtToken, newDebtTokenAddress);
        assertEq(storedConfig.reserveFactor, newDebtReserveFactor);
        assertEq(storedConfig.isFrozen, false);
        assertEq(storedConfig.isPaused, false);

        vm.stopPrank();
    }

    function test_setDebtSupplyCap() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.setDebtSupplyCap(newDebt, newDebtSupplyCap);

        IPool.DebtConfiguration memory storedConfig = pool
            .getDebtAssetConfiguration(newDebt);
        assertEq(storedConfig.supplyCap, newDebtSupplyCap);

        vm.stopPrank();
    }

    function test_setDebtBorrowCap() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.setDebtBorrowCap(newDebt, newDebtBorrowCap);

        IPool.DebtConfiguration memory storedConfig = pool
            .getDebtAssetConfiguration(newDebt);
        assertEq(storedConfig.borrowCap, newDebtBorrowCap);

        vm.stopPrank();
    }

    function test_setDebtReserveFactor() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.setDebtReserveFactor(newDebt, newDebtReserveFactor);

        IPool.DebtConfiguration memory storedConfig = pool
            .getDebtAssetConfiguration(newDebt);
        assertEq(storedConfig.reserveFactor, newDebtReserveFactor);

        vm.stopPrank();
    }

    function test_freezeCollateral() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.freezeCollateral(newCollateral, true);

        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(newCollateral);
        assertEq(storedConfig.isFrozen, true);

        settingManager.freezeCollateral(newCollateral, false);

        storedConfig = pool.getCollateralAssetConfiguration(newCollateral);
        assertEq(storedConfig.isFrozen, false);

        vm.stopPrank();
    }

    function test_freezeDebt() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.freezeDebt(newDebt, true);

        IPool.DebtConfiguration memory storedConfig = pool
            .getDebtAssetConfiguration(newDebt);
        assertEq(storedConfig.isFrozen, true);

        settingManager.freezeDebt(newDebt, false);

        storedConfig = pool.getDebtAssetConfiguration(newDebt);
        assertEq(storedConfig.isFrozen, false);

        vm.stopPrank();
    }

    function test_pauseCollateral() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.pauseCollateral(newCollateral, true);

        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(newCollateral);
        assertEq(storedConfig.isPaused, true);

        settingManager.pauseCollateral(newCollateral, false);

        storedConfig = pool.getCollateralAssetConfiguration(newCollateral);
        assertEq(storedConfig.isPaused, false);

        vm.stopPrank();
    }

    function test_pauseDebt() public {
        _setUpAssets();
        vm.startPrank(settingManagerAdmin);
        settingManager.pauseDebt(newDebt, true);

        IPool.DebtConfiguration memory storedConfig = pool
            .getDebtAssetConfiguration(newDebt);
        assertEq(storedConfig.isPaused, true);

        settingManager.pauseDebt(newDebt, false);

        storedConfig = pool.getDebtAssetConfiguration(newDebt);
        assertEq(storedConfig.isPaused, false);

        vm.stopPrank();
    }

    function test_Upgrade() public {
        vm.startPrank(initialAdmin);
        ProtocolSettingManagerV2 newSettingManagerImpl = new ProtocolSettingManagerV2();
        settingManager.upgradeToAndCall(address(newSettingManagerImpl), "");

        ProtocolSettingManagerV2 newSettingManager = ProtocolSettingManagerV2(
            address(settingManager)
        );
        assertEq(newSettingManager.getVersion(), 2);

        vm.stopPrank();
    }

    function testRevert_initCollateralAssetsNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.initCollateralAsset(newCollateral, collateralConfig);

        vm.stopPrank();
    }

    function testRevert_initDebtAssetsNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.initDebtAsset(newDebt, debtConfig);

        vm.stopPrank();
    }

    function testRevert_setCollateralConfigurationNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.setCollateralConfiguration(
            newCollateral,
            newCollateralConfig
        );

        vm.stopPrank();
    }

    function testRevert_setCollateralLtvNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.setCollateralLtv(newCollateral, newCollateralLtv);
        vm.stopPrank();
    }

    function testRevert_setCollateralLiquidationThresholdNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.setCollateralLiquidationThreshold(
            newCollateral,
            newCollateralLiquidationThreshold
        );
    }

    function testRevert_setCollateralLiquidationProtocolFeeNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.setCollateralLiquidationProtocolFee(
            newCollateral,
            newCollateralLiquidationProtocolFee
        );

        vm.stopPrank();
    }

    function testRevert_setCollateralReserveFactorNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.setCollateralReserveFactor(
            newCollateral,
            newCollateralReserveFactor
        );

        vm.stopPrank();
    }

    function testRevert_setCollateralLiquidationBonusNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.setCollateralLiquidationBonus(
            newCollateral,
            newCollateralLiquidationBonus
        );

        vm.stopPrank();
    }

    function testRevert_setCollateralSupplyCapNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.setCollateralSupplyCap(
            newCollateral,
            newCollateralSupplyCap
        );

        vm.stopPrank();
    }

    function testRevert_setCollateralBorrowCapNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.setCollateralBorrowCap(
            newCollateral,
            newCollateralBorrowCap
        );

        vm.stopPrank();
    }

    function testRevert_setDebtConfigurationNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.setDebtConfiguration(newDebt, newDebtConfig);

        vm.stopPrank();
    }

    function testRevert_setDebtSupplyCapNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.setDebtSupplyCap(newDebt, newDebtSupplyCap);

        vm.stopPrank();
    }

    function testRevert_setDebtBorrowCapNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.setDebtBorrowCap(newDebt, newDebtBorrowCap);

        vm.stopPrank();
    }

    function testRevert_setDebtReserveFactorNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.setDebtReserveFactor(newDebt, newDebtReserveFactor);

        vm.stopPrank();
    }

    function testRevert_freezeCollateralNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.freezeCollateral(newCollateral, true);

        vm.stopPrank();
    }

    function testRevert_freezeDebtNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.freezeDebt(newDebt, true);

        vm.stopPrank();
    }

    function testRevert_pauseCollateralNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.pauseCollateral(newCollateral, true);

        vm.stopPrank();
    }

    function testRevert_pauseDebtNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.pauseDebt(newDebt, true);

        vm.stopPrank();
    }

    function testRevert_UpgradeNotAdmin() public {
        vm.startPrank(alice);

        ProtocolSettingManagerV2 newSettingManagerImpl = new ProtocolSettingManagerV2();

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        settingManager.upgradeToAndCall(address(newSettingManagerImpl), "");

        vm.stopPrank();
    }
}
