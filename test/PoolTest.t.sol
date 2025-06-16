// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Pool} from "../src/pool/Pool.sol";
import {IPool} from "../src/interfaces/pool/IPool.sol";
import {HEALTH_FACTOR_BASE, ETH_ADDRESS, INITIAL_ADMIN, POOL_ADMIN, VAULT_ADMIN, SETTING_MANAGER_ADMIN, EURC_PRECISION, LINK_PRECISION} from "../src/helpers/Constants.sol";
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
import {MockTokenEURC} from "../src/mock/MockTokenEURC.sol";

// Interfaces for testing
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

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
    MockTokenEURC eurToken;
    MockWETH wETH;
    MockRETH rETH;
    MockLido stETH;
    MockPriorityPool linkPriorityPool;
    MockWithdrawalQueue withdrawalQueue;
    MockMorphoVault morphoVault;
    MockRocketDepositPool rocketDepositPool;
    MockRocketDAOSettings rocketDAOSettings;
    MockChainlinkOracleManager oracleManager;

    // Test alices
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public liquidator = makeAddr("liquidator");
    address public initialAdmin = INITIAL_ADMIN;
    address public poolAdmin = POOL_ADMIN;
    address public vaultAdmin = VAULT_ADMIN;
    address public settingManagerAdmin = SETTING_MANAGER_ADMIN;

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
        eurToken.mint(alice, 1000000 * EURC_PRECISION);
        eurToken.mint(bob, 1000000 * EURC_PRECISION);
        linkToken.mint(alice, 1000 * LINK_PRECISION);
        linkToken.mint(bob, 1000 * LINK_PRECISION);
    }

    function test_Initialize() public view {
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
            borrowCap: 800000e6,
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

    function test_SetCollateralConfiguration() public {
        IPool.CollateralConfiguration memory newConfig = IPool
            .CollateralConfiguration({
                supplyCap: 15000e18, // Changed from 10000e18
                borrowCap: 12000e18, // Changed from 8000e18
                colToken: address(colETH),
                tokenVault: address(ethVault),
                ltv: 7500, // Changed from 8000
                liquidationThreshold: 8000, // Changed from 8500
                liquidationBonus: 600, // Changed from 500
                liquidationProtocolFee: 1000,
                reserveFactor: 1000,
                isFrozen: false,
                isPaused: false
            });

        vm.prank(poolAdmin);
        vm.expectEmit(true, false, false, true);
        emit IPool.SetCollateralConfiguration(ETH_ADDRESS, newConfig);
        pool.setCollateralConfiguration(ETH_ADDRESS, newConfig);

        IPool.CollateralConfiguration memory storedConfig = pool
            .getCollateralAssetConfiguration(ETH_ADDRESS);
        assertEq(storedConfig.ltv, 7500);
        assertEq(storedConfig.liquidationThreshold, 8000);
        assertEq(storedConfig.liquidationBonus, 600);
        assertEq(storedConfig.supplyCap, 15000e18);
    }

    function test_SetDebtConfiguration() public {
        IPool.DebtConfiguration memory newConfig = IPool.DebtConfiguration({
            supplyCap: 2000000e6, // Changed from 1000000e6
            borrowCap: 1600000e6, // Changed from 800000e6
            colToken: address(colEUR),
            debtToken: address(debtEUR),
            reserveFactor: 1500, // Changed from 1000
            isFrozen: false,
            isPaused: false
        });

        vm.prank(poolAdmin);
        vm.expectEmit(true, false, false, true);
        emit IPool.SetDebtConfiguration(address(eurToken), newConfig);
        pool.setDebtConfiguration(address(eurToken), newConfig);

        IPool.DebtConfiguration memory storedConfig = pool
            .getDebtAssetConfiguration(address(eurToken));
        assertEq(storedConfig.supplyCap, 2000000e6);
        assertEq(storedConfig.reserveFactor, 1500);
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

        // Check alice received ETH
        assertApproxEqAbs(
            alice.balance,
            aliceBalanceBefore + withdrawAmount,
            0.0001 ether,
            "ETH balance not equal to expected"
        );
    }

    function test_WithdrawETHFromEtherfi(
        uint256 supplyAmount,
        uint256 withdrawAmount
    ) public {
        vm.assume(supplyAmount >= 1 ether && supplyAmount <= alice.balance);
        vm.assume(withdrawAmount > 0 && withdrawAmount <= supplyAmount);

        vm.startPrank(vaultAdmin);
        ethVault.updateCurrentStakingRouter(address(routerETHEtherfi));
        ethVault.updateCurrentUnstakingRouter(address(routerETHEtherfi));
        vm.stopPrank();
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

        // Check alice received ETH
        assertApproxEqAbs(
            alice.balance,
            aliceBalanceBefore + withdrawAmount,
            0.0001 ether,
            "ETH balance not equal to expected"
        );
        vm.stopPrank();
    }

    function test_WithdrawETHFromMorpho(
        uint256 supplyAmount,
        uint256 withdrawAmount
    ) public {
        vm.assume(supplyAmount >= 1 ether && supplyAmount <= alice.balance);
        vm.assume(withdrawAmount > 0 && withdrawAmount <= supplyAmount);

        vm.startPrank(vaultAdmin);
        ethVault.updateCurrentStakingRouter(address(routerETHMorpho));
        ethVault.updateCurrentUnstakingRouter(address(routerETHMorpho));
        vm.stopPrank();
    }

    function test_WithdrawLINK(
        uint256 supplyAmount,
        uint256 withdrawAmount
    ) public {
        vm.assume(
            supplyAmount >= 1000e18 &&
                supplyAmount <= linkToken.balanceOf(alice)
        );
        vm.assume(withdrawAmount > 0 && withdrawAmount <= supplyAmount);

        vm.startPrank(alice);
        linkToken.approve(address(pool), supplyAmount);
        pool.supply(address(linkToken), supplyAmount, alice);

        vm.stopPrank();
    }

    function test_WithdrawEUR(
        uint256 supplyAmount,
        uint256 withdrawAmount
    ) public {
        vm.assume(
            supplyAmount >= 1 * EURC_PRECISION &&
                supplyAmount <= eurToken.balanceOf(alice)
        );
        vm.assume(withdrawAmount > 0 && withdrawAmount <= supplyAmount);

        vm.startPrank(alice);
        eurToken.approve(address(pool), supplyAmount);
        pool.supply(address(eurToken), supplyAmount, alice);

        uint256 colEURBalanceBefore = colEUR.balanceOf(alice);
        uint256 eurTokenBalanceBefore = eurToken.balanceOf(alice);

        colEUR.approve(address(pool), withdrawAmount);
        pool.withdraw(address(eurToken), withdrawAmount, alice);

        uint256 colEURBalanceAfter = colEUR.balanceOf(alice);
        uint256 eurTokenBalanceAfter = eurToken.balanceOf(alice);

        assertEq(colEURBalanceAfter, colEURBalanceBefore - withdrawAmount);
        assertEq(eurTokenBalanceAfter, eurTokenBalanceBefore + withdrawAmount);

        vm.stopPrank();
    }

    function test_Borrow() public {
        // First supply 50000 EUR to pool for borrowing
        vm.startPrank(bob);
        eurToken.approve(address(pool), 50000e6);
        pool.supply(address(eurToken), 50000e6, bob);
        vm.stopPrank();

        // Supply ETH as collateral
        uint256 collateralAmount = 2 ether; // Deposit 2 ETH = 6000 USD
        vm.prank(alice);
        pool.supply{value: collateralAmount}(
            ETH_ADDRESS,
            collateralAmount,
            alice
        );

        // Calculate borrowable amount
        // ETH value: 2 * $3000 = $6000
        // LTV 80%: $4800 borrowable
        // EUR price: $1.08, so max borrow: $4800 / $1.08 = ~4444 EUR
        uint256 borrowAmount = 4000e6; // Borrow 4000 EUR (safe amount)

        uint256 aliceEURBalanceBefore = eurToken.balanceOf(alice);

        vm.prank(alice);
        pool.borrow(address(eurToken), borrowAmount, alice);

        // Check debt token balance
        assertEq(debtEUR.balanceOf(alice), borrowAmount);

        // Check alice received EUR
        assertEq(
            eurToken.balanceOf(alice),
            aliceEURBalanceBefore + borrowAmount
        );
    }

    function test_Repay() public {
        // Setup: supply EUR and collateral, then borrow
        vm.startPrank(alice);
        pool.supply(address(eurToken), 50000e6, alice);
        pool.supply{value: 2 ether}(ETH_ADDRESS, 2 ether, alice);

        uint256 borrowAmount = 4000e6;
        pool.borrow(address(eurToken), borrowAmount, alice);
        vm.stopPrank();

        // Repay half
        uint256 repayAmount = 2000e6;

        vm.prank(alice);
        pool.repay(address(eurToken), repayAmount, alice);

        // Check debt token balance decreased
        assertEq(debtEUR.balanceOf(alice), borrowAmount - repayAmount);
    }

    function test_Liquidate() public {
        // Setup: supply EUR and collateral, then borrow
        vm.startPrank(alice);
        pool.supply(address(eurToken), 50000e6, alice);
        pool.supply{value: 2 ether}(ETH_ADDRESS, 2 ether, alice);
    }

    function test_GetUserAccountData() public {
        // Setup alice position
        vm.startPrank(alice);
        pool.supply(address(eurToken), 50000e6, alice);
        pool.supply{value: 2 ether}(ETH_ADDRESS, 2 ether, alice);
        pool.supply(address(linkToken), 1000e18, alice);

        uint256 borrowAmount = 3000e6;
        pool.borrow(address(eurToken), borrowAmount, alice);
        vm.stopPrank();

        IPool.UserAccountData memory aliceData = pool.getUserAccountData(alice);

        // ETH collateral value: 2 ETH * $3000 = $6000 (in 8 decimals: 600000000000)
        // LINK collateral value: 1000 LINK * $20 = $20000 (in 8 decimals: 2000000000000)
        // Total collateral value: $26000 (in 8 decimals: 2600000000000)
        uint256 expectedCollateralValue = 2600000000000;
        assertEq(aliceData.totalCollateralValue, expectedCollateralValue);

        // Debt value: 3000 EUR * $1.08 = $3240 (in 8 decimals: 324000000000)
        uint256 expectedDebtValue = 324000000000;
        assertEq(aliceData.totalDebtValue, expectedDebtValue);

        // Available borrows should be positive
        assertGt(aliceData.availableBorrowsValue, 0);
    }

    function testRevert_WhenAssetNotAllowed() public {
        MockERC20 invalidToken = new MockERC20("Invalid", "INV");

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IPool.Pool_AssetNotAllowed.selector,
                address(invalidToken)
            )
        );
        pool.supply(address(invalidToken), 1000e18, alice);
    }

    function testRevert_WhenInvalidETHAmount() public {
        vm.prank(alice);
        vm.expectRevert(IPool.Pool_InvalidAmount.selector);
        pool.supply{value: 2 ether}(ETH_ADDRESS, 1 ether, alice); // msg.value != amount
    }

    function testRevert_WhenSupplyCapExceeded() public {
        vm.startPrank(settingManagerAdmin);
        settingManager.setCollateralSupplyCap(ETH_ADDRESS, 10000 ether);
        vm.stopPrank();

        // Try to supply more than supply cap (10000 ETH)
        uint256 excessiveAmount = 15000 ether;

        vm.deal(alice, excessiveAmount);
        vm.prank(alice);
        vm.expectRevert(IPool.Pool_SupplyCapExceeded.selector);
        pool.supply{value: excessiveAmount}(
            ETH_ADDRESS,
            excessiveAmount,
            alice
        );
    }

    function testRevert_WhenCollateralPaused() public {
        vm.startPrank(settingManagerAdmin);
        settingManager.pauseCollateral(ETH_ADDRESS, true);
        vm.stopPrank();

        vm.prank(alice);
        vm.expectRevert(IPool.Pool_CollateralPaused.selector);
        pool.supply{value: 1 ether}(ETH_ADDRESS, 1 ether, alice);
    }

    function testRevert_WhenCollateralFrozen() public {
        vm.startPrank(settingManagerAdmin);
        settingManager.freezeCollateral(ETH_ADDRESS, true);
        vm.stopPrank();

        vm.prank(alice);
        vm.expectRevert(IPool.Pool_CollateralFrozen.selector);
        pool.supply{value: 1 ether}(ETH_ADDRESS, 1 ether, alice);
    }

    function testRevert_WhenInsufficientAvailableBorrows() public {
        // Supply small collateral
        vm.prank(alice);
        pool.supply{value: 0.1 ether}(ETH_ADDRESS, 0.1 ether, alice);

        // Try to borrow more than available
        uint256 excessiveBorrowAmount = 10000e6;

        vm.prank(alice);
        vm.expectRevert(IPool.Pool_InsufficientAvailableBorrowsValue.selector);
        pool.borrow(address(eurToken), excessiveBorrowAmount, alice);
    }

    function testRevert_WhenInsufficientHealthFactor() public {
        vm.startPrank(bob);
        eurToken.approve(address(pool), 10000e6);
        pool.supply(address(eurToken), 10000e6, bob);
        vm.stopPrank();

        // Setup position close to liquidation
        vm.startPrank(alice);
        pool.supply{value: 1 ether}(ETH_ADDRESS, 1 ether, alice);
        // Borrow maximum amount
        uint256 borrowAmount = 2200e6; // Deposit 1 ETH = 3000 USD, borrow 2200 EUR = 2376 USD should fail
        pool.borrow(address(eurToken), borrowAmount, alice);
        console.log(pool.getUserAccountData(alice).availableBorrowsValue);

        // Try to withdraw too much collateral (would break health factor)
        vm.expectRevert(IPool.Pool_InsufficientHealthFactor.selector);
        pool.withdraw(ETH_ADDRESS, 0.8 ether, alice);
        vm.stopPrank();
    }

    function testRevert_WhenUnauthorizedAccess() public {
        IPool.CollateralConfiguration memory config = IPool
            .CollateralConfiguration({
                ltv: 8000,
                liquidationThreshold: 8500,
                liquidationBonus: 500,
                supplyCap: 10000e18,
                borrowCap: 1600000e6,
                isFrozen: false,
                isPaused: false,
                colToken: address(colETH),
                tokenVault: address(ethVault),
                liquidationProtocolFee: 1000,
                reserveFactor: 1000
            });

        // Try to call restricted function without permission
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        pool.initCollateralAsset(ETH_ADDRESS, config);
    }

    function testRevert_WhenAssetAlreadyInitialized() public {
        // Try to initialize ETH again
        IPool.CollateralConfiguration memory config = IPool
            .CollateralConfiguration({
                ltv: 8000,
                liquidationThreshold: 8500,
                liquidationBonus: 500,
                supplyCap: 10000e18,
                borrowCap: 1600000e6,
                isFrozen: false,
                isPaused: false,
                colToken: address(colETH),
                tokenVault: address(ethVault),
                liquidationProtocolFee: 1000,
                reserveFactor: 1000
            });

        vm.prank(poolAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(
                IPool.Pool_AssetAlreadyInitialized.selector,
                ETH_ADDRESS
            )
        );
        pool.initCollateralAsset(ETH_ADDRESS, config);
    }

    function test_EmitEvents() public {
        // Test supply event
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit IPool.Supply(ETH_ADDRESS, 1 ether, alice, alice);
        pool.supply{value: 1 ether}(ETH_ADDRESS, 1 ether, alice);

        // Test withdraw event
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit IPool.Withdraw(ETH_ADDRESS, 0.5 ether, alice, alice);
        pool.withdraw(ETH_ADDRESS, 0.5 ether, alice);

        // Setup for borrow/repay events
        vm.prank(alice);
        pool.supply(address(eurToken), 50000e6, alice);

        // Test borrow event
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit IPool.Borrow(address(eurToken), 1000e6, alice, alice);
        pool.borrow(address(eurToken), 1000e6, alice);

        // Test repay event
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit IPool.Repay(address(eurToken), 500e6, alice, alice);
        pool.repay(address(eurToken), 500e6, alice);
    }

    function test_MultipleAssetSupply() public {
        vm.startPrank(alice);

        // Supply multiple collateral assets
        pool.supply{value: 5 ether}(ETH_ADDRESS, 5 ether, alice);
        pool.supply(address(linkToken), 2000e18, alice);
        pool.supply(address(eurToken), 10000e6, alice);

        vm.stopPrank();

        // Check balances
        assertEq(colETH.balanceOf(alice), 5 ether);
        assertEq(colLINK.balanceOf(alice), 2000e18);
        assertEq(colEUR.balanceOf(alice), 10000e6);

        // Check alice account data
        IPool.UserAccountData memory aliceData = pool.getUserAccountData(alice);

        // ETH: 5 * $3000 = $15000
        // LINK: 2000 * $20 = $40000
        // Total: $55000 (in 8 decimals: 5500000000000)
        uint256 expectedCollateralValue = 5500000000000;
        assertEq(aliceData.totalCollateralValue, expectedCollateralValue);
    }

    function testEdgeCase_ZeroSupply() public {
        vm.prank(alice);
        vm.expectRevert(IPool.Pool_InvalidAmount.selector);
        pool.supply{value: 0}(ETH_ADDRESS, 0, alice);
    }

    function testEdgeCase_ZeroWithdraw() public {
        vm.prank(alice);
        vm.expectRevert(IPool.Pool_InvalidAmount.selector);
        pool.withdraw(ETH_ADDRESS, 0, alice);
    }

    function testEdgeCase_ZeroBorrow() public {
        vm.prank(alice);
        vm.expectRevert(IPool.Pool_InvalidAmount.selector);
        pool.borrow(address(eurToken), 0, alice);
    }

    function testEdgeCase_ZeroRepay() public {
        vm.prank(alice);
        vm.expectRevert(IPool.Pool_InvalidAmount.selector);
        pool.repay(address(eurToken), 0, alice);
    }
}
