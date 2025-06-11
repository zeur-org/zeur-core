// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Pool} from "../../src/pool/Pool.sol";
import {IPool} from "../../src/interfaces/pool/IPool.sol";
import {HEALTH_FACTOR_BASE, ETH_ADDRESS, INITIAL_ADMIN, POOL_ADMIN, VAULT_ADMIN} from "../../src/helpers/Constants.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TestSetupLocalHelpers} from "./TestSetupLocalHelpers.s.sol";

// Core contracts
import {Pool} from "../src/pool/Pool.sol";
import {PoolData} from "../src/pool/PoolData.sol";
import {ProtocolAccessManager} from "../src/pool/manager/ProtocolAccessManager.sol";
import {ProtocolSettingManager} from "../src/pool/manager/ProtocolSettingManager.sol";
import {ProtocolVaultManager} from "../src/pool/manager/ProtocolVaultManager.sol";
import {ChainlinkOracleManager} from "../src/chainlink/ChainlinkOracleManager.sol";
// Staking routers
import {StakingRouterLINK} from "../src/pool/router/StakingRouterLINK.sol";
import {StakingRouterETHLido} from "../src/pool/router/StakingRouterETHLido.sol";
import {StakingRouterETHMorpho} from "../src/pool/router/StakingRouterETHMorpho.sol";
import {StakingRouterETHEtherfi} from "../src/pool/router/StakingRouterETHEtherfi.sol";
import {StakingRouterETHRocketPool} from "../src/pool/router/StakingRouterETHRocketPool.sol";
// Tokenization
import {ColEUR} from "../src/pool/tokenization/ColEUR.sol";
import {ColToken} from "../src/pool/tokenization/ColToken.sol";
import {DebtEUR} from "../src/pool/tokenization/DebtEUR.sol";
// Vaults
import {VaultETH} from "../src/pool/vault/VaultETH.sol";
import {VaultLINK} from "../src/pool/vault/VaultLINK.sol";
// Mock contracts
import {MockChainlinkOracleManager, MockERC20, MockPriorityPool, MockWithdrawalQueue, MockMorphoVault, MockWETH, MockRETH, MockRocketDepositPool, MockRocketDAOSettings} from "./TestMockHelpers.sol";
import {MockLido} from "../src/mock/MockLido.sol";

contract PoolTest is Test {
    Pool private pool;
    PoolData private poolData;
    ProtocolAccessManager private accessManager;
    ProtocolSettingManager private settingManager;
    ProtocolVaultManager private vaultManager;

    ColToken private colETH;
    ColToken private colLINK;
    ColEUR private colEUR;
    DebtEUR private debtEUR;

    VaultETH private ethVault;
    VaultLINK private linkVault;

    StakingRouterLINK private routerLINK;
    StakingRouterETHLido private routerETHLido;
    StakingRouterETHMorpho private routerETHMorpho;
    StakingRouterETHEtherfi private routerETHEtherfi;
    StakingRouterETHRocketPool private routerETHRocketPool;

    MockERC20 linkToken;
    MockERC20 stLinkToken;
    MockERC20 eurToken;
    MockWETH wETH;
    MockRETH rETH;
    MockLido stETH;
    MockPriorityPool linkPriorityPool;
    MockWithdrawalQueue withdrawalQueue;
    MockMorphoVault morphoVault;
    MockRocketDepositPool rocketDepositPool;
    MockRocketDAOSettings rocketDAOSettings;
    MockChainlinkOracleManager oracleManager;

    // Test users
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public liquidator = makeAddr("liquidator");
    address public initialAdmin = INITIAL_ADMIN;
    address public poolAdmin = POOL_ADMIN;
    address public vaultAdmin = VAULT_ADMIN;

    // Constants
    uint256 public constant INITIAL_ETH_PRICE = 3000e8; // $3000 in 8 decimals
    uint256 public constant INITIAL_LINK_PRICE = 20e8; // $20 in 8 decimals
    uint256 public constant INITIAL_EUR_PRICE = 108e6; // $1.08 in 8 decimals (EUR has 6 decimals)
    uint256 public constant MIN_STAKING_AMOUNT = 0.01 ether;

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

        pool = coreContracts.pool;
        poolData = coreContracts.poolData;
        accessManager = coreContracts.accessManager;
        settingManager = coreContracts.settingManager;
        vaultManager = coreContracts.vaultManager;

        colEUR = tokenizationContracts.colEUR;
        colETH = tokenizationContracts.colETH;
        colLINK = tokenizationContracts.colLINK;
        debtEUR = tokenizationContracts.debtEUR;

        ethVault = vaultContracts.vaultETH;
        linkVault = vaultContracts.vaultLINK;

        routerLINK = stakingRouters.stakingRouterLINK;
        routerETHLido = stakingRouters.stakingRouterETHLido;
        routerETHMorpho = stakingRouters.stakingRouterETHMorpho;
        routerETHEtherfi = stakingRouters.stakingRouterETHEtherfi;
        routerETHRocketPool = stakingRouters.stakingRouterETHRocketPool;

        linkToken = mockContracts.linkToken;
        stLinkToken = mockContracts.stLinkToken;
        eurToken = mockContracts.eurToken;
        wETH = mockContracts.wETH;
        rETH = mockContracts.rETH;
        stETH = mockContracts.stETH;
        linkPriorityPool = mockContracts.linkPriorityPool;
        withdrawalQueue = mockContracts.withdrawalQueue;
        morphoVault = mockContracts.morphoVault;
        rocketDepositPool = mockContracts.rocketDepositPool;
        rocketDAOSettings = mockContracts.rocketDAOSettings;
        oracleManager = mockContracts.oracleManager;

        console.log("Pool in PoolTest:", address(pool));
        console.log("PoolData in PoolTest:", address(poolData));
        console.log("AccessManager in PoolTest:", address(accessManager));
        console.log("SettingManager in PoolTest:", address(settingManager));
        console.log("VaultManager in PoolTest:", address(vaultManager));

        console.log("ColETH in PoolTest:", address(colETH));
        console.log("ColLINK in PoolTest:", address(colLINK));
        console.log("ColEUR in PoolTest:", address(colEUR));
        console.log("DebtEUR in PoolTest:", address(debtEUR));

        console.log("ETHVault in PoolTest:", address(ethVault));
        console.log("LINKVault in PoolTest:", address(linkVault));

        console.log("RouterLINK in PoolTest:", address(routerLINK));
        console.log("RouterETHLido in PoolTest:", address(routerETHLido));
        console.log("RouterETHMorpho in PoolTest:", address(routerETHMorpho));
        console.log("RouterETHEtherfi in PoolTest:", address(routerETHEtherfi));
        console.log(
            "RouterETHRocketPool in PoolTest:",
            address(routerETHRocketPool)
        );

        console.log("MockOracleManager in PoolTest:", address(oracleManager));

        // Send Ether to alice/bob
        vm.deal(alice, 100 ether); // 100 ETH
        vm.deal(bob, 100 ether); // 100 ETH
        vm.deal(liquidator, 100 ether); // 100 ETH

        // Mint EUR and LINK to alice/bob
        eurToken.mint(alice, 10000e18);
        eurToken.mint(bob, 10000e18);
        linkToken.mint(alice, 1000e18);
        linkToken.mint(bob, 1000e18);
    }

    function test_Initialize() public {
        // Check that pool is properly initialized
        assertEq(pool.getCollateralAssetList().length, 2);
        assertEq(pool.getDebtAssetList().length, 1);
    }

    function test_InitCollateralAsset() public {
        vm.startPrank(poolAdmin);

        address NEW_ETH_ADDRESS = makeAddr("ETH");

        IPool.CollateralConfiguration memory config = IPool
            .CollateralConfiguration({
                supplyCap: 10000e18,
                borrowCap: 8000e18,
                colToken: address(colETH),
                tokenVault: address(ethVault),
                ltv: 8000,
                liquidationThreshold: 8500,
                liquidationBonus: 500,
                liquidationProtocolFee: 1000,
                reserveFactor: 1000,
                isFrozen: false,
                isPaused: false
            });

        vm.expectEmit(true, false, false, true);
        emit IPool.InitCollateralAsset(NEW_ETH_ADDRESS, config);

        pool.initCollateralAsset(NEW_ETH_ADDRESS, config);

        // Verify asset is added to list
        address[] memory collateralAssets = pool.getCollateralAssetList();
        assertEq(collateralAssets.length, 3);
        assertEq(collateralAssets[2], NEW_ETH_ADDRESS);

        // Verify configuration
        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(NEW_ETH_ADDRESS);
        assertEq(storedConfig.ltv, 8000);
        assertEq(storedConfig.liquidationThreshold, 8500);
        assertEq(storedConfig.liquidationBonus, 500);
        assertEq(storedConfig.supplyCap, 10000e18);
        assertEq(storedConfig.colToken, address(colETH));
        assertEq(storedConfig.tokenVault, address(ethVault));

        vm.stopPrank();
    }

    function test_InitDebtAsset() public {
        vm.startPrank(poolAdmin);

        address EURI_ADDRESS = makeAddr("EURI");

        IPool.DebtConfiguration memory config = IPool.DebtConfiguration({
            supplyCap: 1000000e6,
            colToken: address(colEUR),
            debtToken: address(debtEUR),
            reserveFactor: 1000,
            isFrozen: false,
            isPaused: false
        });

        vm.expectEmit(true, false, false, true);
        emit IPool.InitDebtAsset(EURI_ADDRESS, config);

        pool.initDebtAsset(EURI_ADDRESS, config);

        // Verify asset is added to list
        address[] memory debtAssets = pool.getDebtAssetList();
        assertEq(debtAssets.length, 2); // EURC and EURI
        assertEq(debtAssets[1], EURI_ADDRESS);

        // Verify configuration
        IPool.DebtConfiguration memory storedConfig = pool
            .getDebtAssetConfiguration(EURI_ADDRESS);
        assertEq(storedConfig.supplyCap, 1000000e6);
        assertEq(storedConfig.colToken, address(colEUR));
        assertEq(storedConfig.debtToken, address(debtEUR));

        vm.stopPrank();
    }

    function test_SupplyETHToLido(uint256 supplyAmount) public {
        vm.assume(
            supplyAmount >= MIN_STAKING_AMOUNT && supplyAmount <= alice.balance
        );

        console.log("ETH balance before supply:", alice.balance);
        console.log("ColETH balance before supply:", colETH.balanceOf(alice));
        console.log("stETH balance before supply:", stETH.balanceOf(alice));

        vm.prank(alice);
        pool.supply{value: supplyAmount}(ETH_ADDRESS, supplyAmount, alice);

        console.log("ETH balance after supply:", alice.balance);
        console.log("ColETH balance after supply:", colETH.balanceOf(alice));
        console.log(
            "stETH balance of vaultETH after supply:",
            stETH.balanceOf(address(ethVault))
        );

        // Check colETH balance
        assertEq(colETH.balanceOf(alice), supplyAmount);
        assertEq(stETH.balanceOf(address(ethVault)), supplyAmount);
    }

    function test_SupplyETHToEtherfi(uint256 supplyAmount) public {
        vm.assume(
            supplyAmount >= MIN_STAKING_AMOUNT && supplyAmount <= alice.balance
        );

        vm.prank(vaultAdmin);
        ethVault.updateCurrentStakingRouter(address(routerETHEtherfi));

        vm.prank(alice);
        pool.supply{value: supplyAmount}(ETH_ADDRESS, supplyAmount, alice);

        // Check colETH balance
        assertEq(colETH.balanceOf(alice), supplyAmount);
        // assertEq(eETH.balanceOf(address(ethVault)), supplyAmount);
    }

    function test_SupplyETHToRocketPool(uint256 supplyAmount) public {
        vm.assume(
            supplyAmount >= MIN_STAKING_AMOUNT && supplyAmount <= alice.balance
        );

        vm.prank(vaultAdmin);
        ethVault.updateCurrentStakingRouter(address(routerETHRocketPool));

        vm.prank(alice);
        pool.supply{value: supplyAmount}(ETH_ADDRESS, supplyAmount, alice);

        // Check colETH balance
        assertEq(colETH.balanceOf(alice), supplyAmount);
        // assertEq(eETH.balanceOf(address(ethVault)), supplyAmount);
    }

    function test_SupplyETHToMorpho(uint256 supplyAmount) public {
        vm.assume(
            supplyAmount >= MIN_STAKING_AMOUNT && supplyAmount <= alice.balance
        );

        vm.prank(vaultAdmin);
        ethVault.updateCurrentStakingRouter(address(routerETHMorpho));

        vm.prank(alice);
        pool.supply{value: supplyAmount}(ETH_ADDRESS, supplyAmount, alice);

        // Check colETH balance
        assertEq(colETH.balanceOf(alice), supplyAmount);
        // assertEq(eETH.balanceOf(address(ethVault)), supplyAmount);
    }

    function test_SupplyLINK(uint256 supplyAmount) public {
        vm.assume(
            supplyAmount > 0 && supplyAmount <= linkToken.balanceOf(alice)
        );

        vm.prank(alice);
        linkToken.approve(address(pool), supplyAmount);
        pool.supply(address(linkToken), supplyAmount, alice);

        // Check colLINK balance
        assertEq(colLINK.balanceOf(alice), supplyAmount);
    }

    function test_SupplyEUR(uint256 supplyAmount) public {
        vm.assume(
            supplyAmount > 0 && supplyAmount <= eurToken.balanceOf(alice)
        );

        vm.startPrank(alice);
        eurToken.approve(address(pool), supplyAmount);
        pool.supply(address(eurToken), supplyAmount, alice);

        // Check colEUR balance
        assertEq(colEUR.balanceOf(alice), supplyAmount);

        vm.stopPrank();
    }

    function test_WithdrawETHFromLido(
        uint256 supplyAmount,
        uint256 withdrawAmount
    ) public {
        vm.assume(supplyAmount >= 1 ether && supplyAmount <= alice.balance);
        vm.assume(withdrawAmount > 0 && withdrawAmount <= supplyAmount);

        // First supply
        vm.prank(alice);
        pool.supply{value: supplyAmount}(ETH_ADDRESS, supplyAmount, alice);

        uint256 aliceBalanceBefore = alice.balance;
        console.log("Supply amount:", supplyAmount);
        console.log("Withdraw amount:", withdrawAmount);
        console.log("ETH balance before withdraw:", alice.balance);
        console.log("ColETH balance before withdraw:", colETH.balanceOf(alice));

        // Then withdraw
        vm.prank(alice);
        pool.withdraw(ETH_ADDRESS, withdrawAmount, alice);

        console.log("ETH balance after withdraw:", alice.balance);
        console.log("ColETH balance after withdraw:", colETH.balanceOf(alice));
        console.log(
            "ETH balance of vaultETH after withdraw:",
            address(ethVault).balance
        );
        console.log(
            "ETH balance of routerLido after withdraw:",
            address(routerETHLido).balance
        );

        // Check colETH balance decreased
        assertEq(
            colETH.balanceOf(alice),
            supplyAmount - withdrawAmount,
            "ColETH balance not equal to expected"
        );

        // Check user received ETH
        assertApproxEqAbs(
            alice.balance,
            aliceBalanceBefore + withdrawAmount,
            0.0001 ether,
            "ETH balance not equal to expected"
        );
    }

    function test_WithdrawETHFromRocketPool(
        uint256 supplyAmount,
        uint256 withdrawAmount
    ) public {
        vm.assume(supplyAmount >= 1 ether && supplyAmount <= alice.balance);
        vm.assume(withdrawAmount > 0 && withdrawAmount <= supplyAmount);

        vm.startPrank(vaultAdmin);
        ethVault.updateCurrentStakingRouter(address(routerETHRocketPool));
        ethVault.updateCurrentUnstakingRouter(address(routerETHRocketPool));
        vm.stopPrank();

        // First supply
        vm.startPrank(alice);
        pool.supply{value: supplyAmount}(ETH_ADDRESS, supplyAmount, alice);

        uint256 aliceBalanceBefore = alice.balance;
        console.log("Supply amount:", supplyAmount);
        console.log("Withdraw amount:", withdrawAmount);
        console.log("ETH balance before withdraw:", alice.balance);
        console.log("ColETH balance before withdraw:", colETH.balanceOf(alice));

        // Then withdraw
        pool.withdraw(ETH_ADDRESS, withdrawAmount, alice);

        console.log("ETH balance after withdraw:", alice.balance);
        console.log("ColETH balance after withdraw:", colETH.balanceOf(alice));
        console.log(
            "ETH balance of vaultETH after withdraw:",
            address(ethVault).balance
        );
        console.log(
            "ETH balance of routerRocketPool after withdraw:",
            address(routerETHRocketPool).balance
        );

        // Check colETH balance decreased
        assertEq(
            colETH.balanceOf(alice),
            supplyAmount - withdrawAmount,
            "ColETH balance not equal to expected"
        );

        // Check user received ETH
        assertApproxEqAbs(
            alice.balance,
            aliceBalanceBefore + withdrawAmount,
            0.0001 ether,
            "ETH balance not equal to expected"
        );
        vm.stopPrank();
    }

    // function test_Borrow() public {
    //     _setupCollateralAssets();
    //     _setupDebtAssets();

    //     // First supply EUR to pool for borrowing
    //     vm.prank(user);
    //     pool.supply(address(eurToken), 50000e6, user);

    //     // Supply ETH as collateral
    //     uint256 collateralAmount = 2 ether;
    //     vm.prank(user);
    //     pool.supply{value: collateralAmount}(
    //         ETH_ADDRESS,
    //         collateralAmount,
    //         user
    //     );

    //     // Calculate borrowable amount
    //     // ETH value: 2 * $3000 = $6000
    //     // LTV 80%: $4800 borrowable
    //     // EUR price: $1.08, so max borrow: $4800 / $1.08 = ~4444 EUR
    //     uint256 borrowAmount = 4000e6; // Borrow 4000 EUR (safe amount)

    //     uint256 userEURBalanceBefore = eurToken.balanceOf(user);

    //     vm.prank(user);
    //     pool.borrow(address(eurToken), borrowAmount, user);

    //     // Check debt token balance
    //     assertEq(debtEUR.balanceOf(user), borrowAmount);

    //     // Check user received EUR
    //     assertEq(eurToken.balanceOf(user), userEURBalanceBefore + borrowAmount);
    // }

    // function test_Repay() public {
    //     _setupCollateralAssets();
    //     _setupDebtAssets();

    //     // Setup: supply EUR and collateral, then borrow
    //     vm.startPrank(user);
    //     pool.supply(address(eurToken), 50000e6, user);
    //     pool.supply{value: 2 ether}(ETH_ADDRESS, 2 ether, user);

    //     uint256 borrowAmount = 4000e6;
    //     pool.borrow(address(eurToken), borrowAmount, user);
    //     vm.stopPrank();

    //     // Repay half
    //     uint256 repayAmount = 2000e6;

    //     vm.prank(user);
    //     pool.repay(address(eurToken), repayAmount, user);

    //     // Check debt token balance decreased
    //     assertEq(debtEUR.balanceOf(user), borrowAmount - repayAmount);
    // }

    // function test_GetUserAccountData() public {
    //     _setupCollateralAssets();
    //     _setupDebtAssets();

    //     // Setup user position
    //     vm.startPrank(user);
    //     pool.supply(address(eurToken), 50000e6, user);
    //     pool.supply{value: 2 ether}(ETH_ADDRESS, 2 ether, user);
    //     pool.supply(address(linkToken), 1000e18, user);

    //     uint256 borrowAmount = 3000e6;
    //     pool.borrow(address(eurToken), borrowAmount, user);
    //     vm.stopPrank();

    //     IPool.UserAccountData memory userData = pool.getUserAccountData(user);

    //     // ETH collateral value: 2 ETH * $3000 = $6000 (in 8 decimals: 600000000000)
    //     // LINK collateral value: 1000 LINK * $20 = $20000 (in 8 decimals: 2000000000000)
    //     // Total collateral value: $26000 (in 8 decimals: 2600000000000)
    //     uint256 expectedCollateralValue = 2600000000000;
    //     assertEq(userData.totalCollateralValue, expectedCollateralValue);

    //     // Debt value: 3000 EUR * $1.08 = $3240 (in 8 decimals: 324000000000)
    //     uint256 expectedDebtValue = 324000000000;
    //     assertEq(userData.totalDebtValue, expectedDebtValue);

    //     // Available borrows should be positive
    //     assertGt(userData.availableBorrowsValue, 0);
    // }

    // function test_RevertWhenAssetNotAllowed() public {
    //     MockERC20 invalidToken = new MockERC20("Invalid", "INV", 18);

    //     vm.prank(user);
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             IPool.Pool_AssetNotAllowed.selector,
    //             address(invalidToken)
    //         )
    //     );
    //     pool.supply(address(invalidToken), 1000e18, user);
    // }

    // function test_RevertWhenInvalidETHAmount() public {
    //     _setupCollateralAssets();

    //     vm.prank(user);
    //     vm.expectRevert(IPool.Pool_InvalidAmount.selector);
    //     pool.supply{value: 2 ether}(ETH_ADDRESS, 1 ether, user); // msg.value != amount
    // }

    // function test_RevertWhenSupplyCapExceeded() public {
    //     _setupCollateralAssets();

    //     // Try to supply more than supply cap (10000 ETH)
    //     uint256 excessiveAmount = 15000 ether;

    //     vm.deal(user, excessiveAmount);
    //     vm.prank(user);
    //     vm.expectRevert(IPool.Pool_SupplyCapExceeded.selector);
    //     pool.supply{value: excessiveAmount}(ETH_ADDRESS, excessiveAmount, user);
    // }

    // function test_RevertWhenCollateralPaused() public {
    //     vm.startPrank(admin);

    //     IPool.CollateralConfiguration memory config = IPool
    //         .CollateralConfiguration({
    //             ltv: 8000,
    //             liquidationThreshold: 8500,
    //             liquidationBonus: 500,
    //             supplyCap: 10000e18,
    //             isFrozen: false,
    //             isPaused: true, // Paused
    //             colToken: address(colETH),
    //             tokenVault: address(ethVault)
    //         });

    //     pool.initCollateralAsset(ETH_ADDRESS, config);
    //     vm.stopPrank();

    //     vm.prank(user);
    //     vm.expectRevert(IPool.Pool_CollateralPaused.selector);
    //     pool.supply{value: 1 ether}(ETH_ADDRESS, 1 ether, user);
    // }

    // function test_RevertWhenCollateralFrozen() public {
    //     vm.startPrank(admin);

    //     IPool.CollateralConfiguration memory config = IPool
    //         .CollateralConfiguration({
    //             ltv: 8000,
    //             liquidationThreshold: 8500,
    //             liquidationBonus: 500,
    //             supplyCap: 10000e18,
    //             isFrozen: true, // Frozen
    //             isPaused: false,
    //             colToken: address(colETH),
    //             tokenVault: address(ethVault)
    //         });

    //     pool.initCollateralAsset(ETH_ADDRESS, config);
    //     vm.stopPrank();

    //     vm.prank(user);
    //     vm.expectRevert(IPool.Pool_CollateralFrozen.selector);
    //     pool.supply{value: 1 ether}(ETH_ADDRESS, 1 ether, user);
    // }

    // function test_RevertWhenInsufficientAvailableBorrows() public {
    //     _setupCollateralAssets();
    //     _setupDebtAssets();

    //     // Supply small collateral
    //     vm.prank(user);
    //     pool.supply{value: 0.1 ether}(ETH_ADDRESS, 0.1 ether, user);

    //     // Try to borrow more than available
    //     uint256 excessiveBorrowAmount = 10000e6;

    //     vm.prank(user);
    //     vm.expectRevert(IPool.Pool_InsufficientAvailableBorrowsValue.selector);
    //     pool.borrow(address(eurToken), excessiveBorrowAmount, user);
    // }

    // function test_RevertWhenInsufficientHealthFactor() public {
    //     _setupCollateralAssets();
    //     _setupDebtAssets();

    //     // Setup position close to liquidation
    //     vm.startPrank(user);
    //     pool.supply(address(eurToken), 50000e6, user);
    //     pool.supply{value: 1 ether}(ETH_ADDRESS, 1 ether, user);

    //     // Borrow maximum amount
    //     uint256 borrowAmount = 2200e6; // Close to max
    //     pool.borrow(address(eurToken), borrowAmount, user);
    //     vm.stopPrank();

    //     // Try to withdraw too much collateral (would break health factor)
    //     vm.prank(user);
    //     vm.expectRevert(IPool.Pool_InsufficientHealthFactor.selector);
    //     pool.withdraw(ETH_ADDRESS, 0.8 ether, user);
    // }

    // function test_SetCollateralConfiguration() public {
    //     _setupCollateralAssets();

    //     IPool.CollateralConfiguration memory newConfig = IPool
    //         .CollateralConfiguration({
    //             supplyCap: 15000e18, // Changed from 10000e18
    //             borrowCap: 12000e18, // Changed from 8000e18
    //             colToken: address(colETH),
    //             tokenVault: address(ethVault),
    //             ltv: 7500, // Changed from 8000
    //             liquidationThreshold: 8000, // Changed from 8500
    //             liquidationBonus: 600, // Changed from 500
    //             liquidationProtocolFee: 1000,
    //             reserveFactor: 1000,
    //             isFrozen: false,
    //             isPaused: false
    //         });

    //     vm.prank(admin);
    //     vm.expectEmit(true, false, false, true);
    //     emit IPool.SetCollateralConfiguration(ETH_ADDRESS, newConfig);
    //     pool.setCollateralConfiguration(ETH_ADDRESS, newConfig);

    //     IPool.CollateralConfiguration memory storedConfig = pool
    //         .getCollateralAssetConfiguration(ETH_ADDRESS);
    //     assertEq(storedConfig.ltv, 7500);
    //     assertEq(storedConfig.liquidationThreshold, 8000);
    //     assertEq(storedConfig.liquidationBonus, 600);
    //     assertEq(storedConfig.supplyCap, 15000e18);
    // }

    // function test_SetDebtConfiguration() public {
    //     _setupDebtAssets();

    //     IPool.DebtConfiguration memory newConfig = IPool.DebtConfiguration({
    //         supplyCap: 2000000e6, // Changed from 1000000e6
    //         colToken: address(colEUR),
    //         debtToken: address(debtEUR),
    //         reserveFactor: 1500, // Changed from 1000
    //         isFrozen: false,
    //         isPaused: false
    //     });

    //     vm.prank(admin);
    //     vm.expectEmit(true, false, false, true);
    //     emit IPool.SetDebtConfiguration(address(eurToken), newConfig);
    //     pool.setDebtConfiguration(address(eurToken), newConfig);

    //     IPool.DebtConfiguration memory storedConfig = pool
    //         .getDebtAssetConfiguration(address(eurToken));
    //     assertEq(storedConfig.supplyCap, 2000000e6);
    //     assertEq(storedConfig.reserveFactor, 1500);
    // }

    // function test_RevertWhenUnauthorizedAccess() public {
    //     IPool.CollateralConfiguration memory config = IPool
    //         .CollateralConfiguration({
    //             ltv: 8000,
    //             liquidationThreshold: 8500,
    //             liquidationBonus: 500,
    //             supplyCap: 10000e18,
    //             isFrozen: false,
    //             isPaused: false,
    //             colToken: address(colETH),
    //             tokenVault: address(ethVault)
    //         });

    //     // Try to call restricted function without permission
    //     vm.prank(user);
    //     vm.expectRevert();
    //     pool.initCollateralAsset(ETH_ADDRESS, config);
    // }

    // function test_RevertWhenAssetAlreadyInitialized() public {
    //     _setupCollateralAssets();

    //     // Try to initialize ETH again
    //     IPool.CollateralConfiguration memory config = IPool
    //         .CollateralConfiguration({
    //             ltv: 8000,
    //             liquidationThreshold: 8500,
    //             liquidationBonus: 500,
    //             supplyCap: 10000e18,
    //             isFrozen: false,
    //             isPaused: false,
    //             colToken: address(colETH),
    //             tokenVault: address(ethVault)
    //         });

    //     vm.prank(admin);
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             IPool.Pool_AssetAlreadyInitialized.selector,
    //             ETH_ADDRESS
    //         )
    //     );
    //     pool.initCollateralAsset(ETH_ADDRESS, config);
    // }

    // function test_EmitEvents() public {
    //     _setupCollateralAssets();
    //     _setupDebtAssets();

    //     // Test supply event
    //     vm.prank(user);
    //     vm.expectEmit(true, true, true, true);
    //     emit IPool.Supply(ETH_ADDRESS, 1 ether, user, user);
    //     pool.supply{value: 1 ether}(ETH_ADDRESS, 1 ether, user);

    //     // Test withdraw event
    //     vm.prank(user);
    //     vm.expectEmit(true, true, true, true);
    //     emit IPool.Withdraw(ETH_ADDRESS, 0.5 ether, user, user);
    //     pool.withdraw(ETH_ADDRESS, 0.5 ether, user);

    //     // Setup for borrow/repay events
    //     vm.prank(user);
    //     pool.supply(address(eurToken), 50000e6, user);

    //     // Test borrow event
    //     vm.prank(user);
    //     vm.expectEmit(true, true, true, true);
    //     emit IPool.Borrow(address(eurToken), 1000e6, user, user);
    //     pool.borrow(address(eurToken), 1000e6, user);

    //     // Test repay event
    //     vm.prank(user);
    //     vm.expectEmit(true, true, true, true);
    //     emit IPool.Repay(address(eurToken), 500e6, user, user);
    //     pool.repay(address(eurToken), 500e6, user);
    // }

    // function test_MultipleAssetSupply() public {
    //     _setupCollateralAssets();
    //     _setupDebtAssets();

    //     vm.startPrank(user);

    //     // Supply multiple collateral assets
    //     pool.supply{value: 5 ether}(ETH_ADDRESS, 5 ether, user);
    //     pool.supply(address(linkToken), 2000e18, user);
    //     pool.supply(address(eurToken), 10000e6, user);

    //     vm.stopPrank();

    //     // Check balances
    //     assertEq(colETH.balanceOf(user), 5 ether);
    //     assertEq(colLINK.balanceOf(user), 2000e18);
    //     assertEq(colEUR.balanceOf(user), 10000e6);

    //     // Check user account data
    //     IPool.UserAccountData memory userData = pool.getUserAccountData(user);

    //     // ETH: 5 * $3000 = $15000
    //     // LINK: 2000 * $20 = $40000
    //     // Total: $55000 (in 8 decimals: 5500000000000)
    //     uint256 expectedCollateralValue = 5500000000000;
    //     assertEq(userData.totalCollateralValue, expectedCollateralValue);
    // }

    // function test_EdgeCaseZeroSupply() public {
    //     _setupCollateralAssets();

    //     vm.prank(user);
    //     vm.expectRevert(IPool.Pool_InvalidAmount.selector);
    //     pool.supply{value: 0}(ETH_ADDRESS, 0, user);
    // }

    // function test_EdgeCaseZeroWithdraw() public {
    //     _setupCollateralAssets();

    //     vm.prank(user);
    //     vm.expectRevert(IPool.Pool_InvalidAmount.selector);
    //     pool.withdraw(ETH_ADDRESS, 0, user);
    // }

    // function test_EdgeCaseZeroBorrow() public {
    //     _setupDebtAssets();

    //     vm.prank(user);
    //     vm.expectRevert(IPool.Pool_InvalidAmount.selector);
    //     pool.borrow(address(eurToken), 0, user);
    // }

    // function test_EdgeCaseZeroRepay() public {
    //     _setupDebtAssets();

    //     vm.prank(user);
    //     vm.expectRevert(IPool.Pool_InvalidAmount.selector);
    //     pool.repay(address(eurToken), 0, user);
    // }

    // receive() external payable {}
}
