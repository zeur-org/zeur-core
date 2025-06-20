// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Core contracts
import {Pool} from "../../src/pool/Pool.sol";
import {PoolData} from "../../src/pool/PoolData.sol";
import {ProtocolAccessManager} from "../../src/pool/manager/ProtocolAccessManager.sol";
import {ProtocolSettingManager} from "../../src/pool/manager/ProtocolSettingManager.sol";
import {ProtocolVaultManager} from "../../src/pool/manager/ProtocolVaultManager.sol";
import {ChainlinkOracleManager} from "../../src/chainlink/ChainlinkOracleManager.sol";
// Staking routers
import {StakingRouterLINK} from "../../src/pool/router/StakingRouterLINK.sol";
import {StakingRouterETHLido} from "../../src/pool/router/StakingRouterETHLido.sol";
import {StakingRouterETHMorpho} from "../../src/pool/router/StakingRouterETHMorpho.sol";
import {StakingRouterETHEtherfi} from "../../src/pool/router/StakingRouterETHEtherfi.sol";
import {StakingRouterETHRocketPool} from "../../src/pool/router/StakingRouterETHRocketPool.sol";
// Tokenization
import {ColEUR} from "../../src/pool/tokenization/ColEUR.sol";
import {ColToken} from "../../src/pool/tokenization/ColToken.sol";
import {DebtEUR} from "../../src/pool/tokenization/DebtEUR.sol";
// Vaults
import {VaultETH} from "../../src/pool/vault/VaultETH.sol";
import {VaultLINK} from "../../src/pool/vault/VaultLINK.sol";
// Interfaces
import {IPool} from "../../src/interfaces/pool/IPool.sol";
import {IChainlinkOracleManager} from "../../src/interfaces/chainlink/IChainlinkOracleManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ETH_ADDRESS, INITIAL_ADMIN, POOL_ADMIN, SETTING_MANAGER_ADMIN, VAULT_ADMIN, BPS_BASE, EURC_PRECISION, EURI_PRECISION, LINK_PRECISION} from "../../src/helpers/Constants.sol";
import {Roles} from "../../src/helpers/Roles.sol";

// Mock contracts
import {MockChainlinkOracleManager, MockERC20, MockWithdrawalQueue, MockWETH, MockRETH, MockRocketDepositPool, MockRocketDAOSettings} from "./TestMockHelpers.sol";
import {MockMorpho} from "../../src/mock/MockMorpho.sol";
import {MockLido} from "../../src/mock/MockLido.sol";
import {MockTokenEURC} from "../../src/mock/MockTokenEURC.sol";
import {MockEETH, MockLiquidityPool} from "../../src/mock/MockEtherfi.sol";
import {MockstLINK, MockPriorityPool} from "../../src/mock/MockStakeLink.sol";

contract TestSetupLocalHelpers is Script {
    address public initialAdmin = INITIAL_ADMIN;
    address public settingManagerAdmin = SETTING_MANAGER_ADMIN;
    address public poolAdmin = POOL_ADMIN;
    address public vaultAdmin = VAULT_ADMIN;

    struct CoreContracts {
        Pool pool;
        PoolData poolData;
        ProtocolAccessManager accessManager;
        ProtocolSettingManager settingManager;
        ProtocolVaultManager vaultManager;
    }

    struct TokenizationContracts {
        ColToken colETH;
        ColToken colLINK;
        ColEUR colEUR;
        DebtEUR debtEUR;
    }

    struct VaultContracts {
        VaultETH vaultETH;
        VaultLINK vaultLINK;
    }

    struct StakingRouters {
        StakingRouterLINK stakingRouterLINK;
        StakingRouterETHLido stakingRouterETHLido;
        StakingRouterETHMorpho stakingRouterETHMorpho;
        StakingRouterETHEtherfi stakingRouterETHEtherfi;
        StakingRouterETHRocketPool stakingRouterETHRocketPool;
    }

    struct MockContracts {
        MockTokenEURC eurToken; // EUR token
        MockLido stETH; // Lido stETH
        MockWithdrawalQueue withdrawalQueue; // Lido withdrawal queue
        MockEETH eETH; // Etherfi eETH
        MockLiquidityPool liquidityPool; // Etherfi liquidity pool
        MockWETH wETH; // Morpho WETH
        MockMorpho morphoVault; // Morpho vault
        MockRETH rETH; // Rocket Pool rETH
        MockRocketDepositPool rocketDepositPool; // Rocket Pool deposit pool
        MockRocketDAOSettings rocketDAOSettings; // Rocket Pool DAO settings
        MockERC20 linkToken; // Chainlink LINK token
        MockstLINK stLinkToken; // Stake.Link stLINK token
        MockPriorityPool linkPriorityPool; // Stake.Link priority pool
        MockChainlinkOracleManager oracleManager; // Chainlink oracle manager
    }

    CoreContracts public coreContracts;
    StakingRouters public stakingRouters;
    TokenizationContracts public tokenizationContracts;
    VaultContracts public vaultContracts;
    MockContracts public mockContracts;

    address public admin;

    function setUp() public {
        admin = address(this);
    }

    function deployAll()
        public
        returns (
            CoreContracts memory,
            TokenizationContracts memory,
            VaultContracts memory,
            StakingRouters memory,
            MockContracts memory
        )
    {
        // Deploy mock external contracts first
        _deployMockContracts();

        // Deploy core protocol contracts
        _deployAccessManager();
        _deployPool();
        _deployPoolData();
        _deployManagers();

        // Deploy tokenization contracts
        _deployTokenizationContracts();

        // Deploy vaults
        _deployVaults();

        // Deploy staking routers
        _deployStakingRouters();

        // Setup initial configurations
        _setupInitialConfigurations();

        return (
            coreContracts,
            tokenizationContracts,
            vaultContracts,
            stakingRouters,
            mockContracts
        );
    }

    function _deployMockContracts() internal {
        // Deploy mock tokens
        mockContracts.linkToken = new MockERC20("Chainlink Token", "LINK");
        mockContracts.eurToken = new MockTokenEURC("Euro Token", "EUR");

        // Deploy mock external protocol contracts
        // Mock Lido
        mockContracts.stETH = new MockLido();
        mockContracts.withdrawalQueue = new MockWithdrawalQueue();
        // Mock Etherfi
        mockContracts.eETH = new MockEETH();
        mockContracts.liquidityPool = new MockLiquidityPool(
            address(mockContracts.eETH)
        );
        // Mock Morpho
        mockContracts.wETH = new MockWETH();
        mockContracts.morphoVault = new MockMorpho(
            "Morpho WETH",
            "morphoWETH",
            address(mockContracts.wETH)
        );

        // Mock Rocket Pool
        mockContracts.rETH = new MockRETH();
        mockContracts.rocketDepositPool = new MockRocketDepositPool();
        mockContracts.rocketDAOSettings = new MockRocketDAOSettings();

        // Mock Stake.Link
        mockContracts.stLinkToken = new MockstLINK(
            address(mockContracts.linkToken)
        );
        mockContracts.linkPriorityPool = new MockPriorityPool(
            address(mockContracts.linkToken),
            address(mockContracts.stLinkToken)
        );

        // Mock oracle manager and set proper asset prices
        mockContracts.oracleManager = new MockChainlinkOracleManager();
        mockContracts.oracleManager.setAssetPrice(ETH_ADDRESS, 3000 * 1e8); // $3000
        mockContracts.oracleManager.setAssetPrice(
            address(mockContracts.linkToken),
            20 * 1e8
        ); // $20
        mockContracts.oracleManager.setAssetPrice(
            address(mockContracts.eurToken),
            108 * 1e6
        ); // $1.08

        console.log("Mock contracts deployed");
    }

    function _deployAccessManager() internal {
        ProtocolAccessManager protocolAccessManagerImpl = new ProtocolAccessManager();
        ERC1967Proxy protocolAccessManagerProxy = new ERC1967Proxy(
            address(protocolAccessManagerImpl),
            abi.encodeWithSelector(
                ProtocolAccessManager.initialize.selector,
                initialAdmin
            )
        );

        coreContracts.accessManager = ProtocolAccessManager(
            address(protocolAccessManagerProxy)
        );

        console.log(
            "ProtocolAccessManager deployed at:",
            address(coreContracts.accessManager)
        );
    }

    function _deployPool() internal {
        Pool poolImpl = new Pool();
        ERC1967Proxy poolProxy = new ERC1967Proxy(
            address(poolImpl),
            abi.encodeWithSelector(
                Pool.initialize.selector,
                address(coreContracts.accessManager),
                address(mockContracts.oracleManager)
            )
        );

        coreContracts.pool = Pool(address(poolProxy));

        console.log("Pool deployed at:", address(coreContracts.pool));
    }

    function _deployPoolData() internal {
        PoolData poolDataImpl = new PoolData();
        ERC1967Proxy poolDataProxy = new ERC1967Proxy(
            address(poolDataImpl),
            abi.encodeWithSelector(
                PoolData.initialize.selector,
                address(coreContracts.accessManager),
                address(coreContracts.pool),
                address(mockContracts.oracleManager)
            )
        );

        coreContracts.poolData = PoolData(address(poolDataProxy));

        console.log("PoolData deployed at:", address(coreContracts.poolData));
    }

    function _deployManagers() internal {
        // Deploy ProtocolSettingManager
        ProtocolSettingManager protocolSettingManagerImpl = new ProtocolSettingManager();
        ERC1967Proxy protocolSettingManagerProxy = new ERC1967Proxy(
            address(protocolSettingManagerImpl),
            abi.encodeWithSelector(
                ProtocolSettingManager.initialize.selector,
                address(coreContracts.accessManager),
                address(coreContracts.pool)
            )
        );

        coreContracts.settingManager = ProtocolSettingManager(
            address(protocolSettingManagerProxy)
        );

        // Deploy ProtocolVaultManager
        ProtocolVaultManager protocolVaultManagerImpl = new ProtocolVaultManager();
        ERC1967Proxy protocolVaultManagerProxy = new ERC1967Proxy(
            address(protocolVaultManagerImpl),
            abi.encodeWithSelector(
                ProtocolVaultManager.initialize.selector,
                address(coreContracts.accessManager)
            )
        );

        coreContracts.vaultManager = ProtocolVaultManager(
            address(protocolVaultManagerProxy)
        );

        console.log("Managers deployed");
    }

    function _deployTokenizationContracts() internal {
        // Deploy ColTokens
        ColToken colETHImpl = new ColToken();
        ERC1967Proxy colETHProxy = new ERC1967Proxy(
            address(colETHImpl),
            abi.encodeWithSelector(
                ColToken.initialize.selector,
                address(coreContracts.accessManager),
                "Collateral ETH",
                "colETH"
            )
        );

        tokenizationContracts.colETH = ColToken(address(colETHProxy));

        ColToken colLINKImpl = new ColToken();
        ERC1967Proxy colLINKProxy = new ERC1967Proxy(
            address(colLINKImpl),
            abi.encodeWithSelector(
                ColToken.initialize.selector,
                address(coreContracts.accessManager),
                "Collateral LINK",
                "colLINK"
            )
        );

        tokenizationContracts.colLINK = ColToken(address(colLINKProxy));

        // Deploy ColEUR
        ColEUR colEURImpl = new ColEUR();
        ERC1967Proxy colEURProxy = new ERC1967Proxy(
            address(colEURImpl),
            abi.encodeWithSelector(
                ColEUR.initialize.selector,
                address(coreContracts.accessManager),
                "Collateral EUR",
                "colEUR",
                IERC20(address(mockContracts.eurToken))
            )
        );

        tokenizationContracts.colEUR = ColEUR(address(colEURProxy));

        // Deploy DebtEUR
        DebtEUR debtEURImpl = new DebtEUR();
        ERC1967Proxy debtEURProxy = new ERC1967Proxy(
            address(debtEURImpl),
            abi.encodeWithSelector(
                DebtEUR.initialize.selector,
                address(coreContracts.accessManager),
                "Debt EUR",
                "debtEUR"
            )
        );

        tokenizationContracts.debtEUR = DebtEUR(address(debtEURProxy));

        console.log("Tokenization contracts deployed");
    }

    function _deployVaults() internal {
        // Deploy VaultETH
        VaultETH vaultETHImpl = new VaultETH();
        ERC1967Proxy vaultETHProxy = new ERC1967Proxy(
            address(vaultETHImpl),
            abi.encodeWithSelector(
                VaultETH.initialize.selector,
                address(coreContracts.accessManager)
            )
        );

        vaultContracts.vaultETH = VaultETH(payable(address(vaultETHProxy)));

        // Deploy VaultLINK
        VaultLINK vaultLINKImpl = new VaultLINK();
        ERC1967Proxy vaultLINKProxy = new ERC1967Proxy(
            address(vaultLINKImpl),
            abi.encodeWithSelector(
                VaultLINK.initialize.selector,
                address(coreContracts.accessManager),
                address(mockContracts.linkToken)
            )
        );

        vaultContracts.vaultLINK = VaultLINK(address(vaultLINKProxy));

        console.log("Vaults deployed");
    }

    function _deployStakingRouters() internal {
        _deployStakingRouterLido();
        _deployStakingRouterEtherfi();
        _deployStakingRouterRocketPool();
        _deployStakingRouterMorpho();
        _deployStakingRouterLINK();

        console.log("Staking routers deployed");
    }

    function _deployStakingRouterLido() internal {
        StakingRouterETHLido stakingRouterETHLidoImpl = new StakingRouterETHLido();
        ERC1967Proxy stakingRouterETHLidoProxy = new ERC1967Proxy(
            address(stakingRouterETHLidoImpl),
            abi.encodeWithSelector(
                StakingRouterETHLido.initialize.selector,
                address(coreContracts.accessManager),
                address(mockContracts.stETH),
                address(mockContracts.withdrawalQueue)
            )
        );

        stakingRouters.stakingRouterETHLido = StakingRouterETHLido(
            address(stakingRouterETHLidoProxy)
        );
    }

    function _deployStakingRouterEtherfi() internal {
        StakingRouterETHEtherfi stakingRouterETHEtherfiImpl = new StakingRouterETHEtherfi();
        ERC1967Proxy stakingRouterETHEtherfiProxy = new ERC1967Proxy(
            address(stakingRouterETHEtherfiImpl),
            abi.encodeWithSelector(
                StakingRouterETHEtherfi.initialize.selector,
                address(coreContracts.accessManager),
                address(mockContracts.eETH),
                address(mockContracts.liquidityPool)
            )
        );

        stakingRouters.stakingRouterETHEtherfi = StakingRouterETHEtherfi(
            address(stakingRouterETHEtherfiProxy)
        );
    }

    function _deployStakingRouterRocketPool() internal {
        StakingRouterETHRocketPool stakingRouterETHRocketPoolImpl = new StakingRouterETHRocketPool();
        ERC1967Proxy stakingRouterETHRocketPoolProxy = new ERC1967Proxy(
            address(stakingRouterETHRocketPoolImpl),
            abi.encodeWithSelector(
                StakingRouterETHRocketPool.initialize.selector,
                address(coreContracts.accessManager),
                address(mockContracts.rETH),
                address(mockContracts.rocketDepositPool),
                address(mockContracts.rocketDAOSettings)
            )
        );

        stakingRouters.stakingRouterETHRocketPool = StakingRouterETHRocketPool(
            address(stakingRouterETHRocketPoolProxy)
        );
    }

    function _deployStakingRouterMorpho() internal {
        StakingRouterETHMorpho stakingRouterETHMorphoImpl = new StakingRouterETHMorpho();
        ERC1967Proxy stakingRouterETHMorphoProxy = new ERC1967Proxy(
            address(stakingRouterETHMorphoImpl),
            abi.encodeWithSelector(
                StakingRouterETHMorpho.initialize.selector,
                address(coreContracts.accessManager),
                address(mockContracts.wETH),
                address(mockContracts.morphoVault)
            )
        );

        stakingRouters.stakingRouterETHMorpho = StakingRouterETHMorpho(
            payable(address(stakingRouterETHMorphoProxy))
        );
    }

    function _deployStakingRouterLINK() internal {
        StakingRouterLINK stakingRouterLINKImpl = new StakingRouterLINK();
        ERC1967Proxy stakingRouterLINKProxy = new ERC1967Proxy(
            address(stakingRouterLINKImpl),
            abi.encodeWithSelector(
                StakingRouterLINK.initialize.selector,
                address(coreContracts.accessManager),
                address(mockContracts.linkToken),
                address(mockContracts.stLinkToken),
                address(mockContracts.linkPriorityPool)
            )
        );

        stakingRouters.stakingRouterLINK = StakingRouterLINK(
            address(stakingRouterLINKProxy)
        );
    }

    function _setupInitialConfigurations() internal {
        _setupAccessManager();

        // Setup asset configurations in the pool
        vm.startPrank(poolAdmin);
        _setupETHConfiguration();
        _setupLINKConfiguration();
        _setupEURConfiguration();
        vm.stopPrank();

        // Setup vault staking routers
        _setupVaultRouters();

        console.log("Initial configurations set up");
    }

    function _setupAccessManager() internal {
        vm.startPrank(initialAdmin);
        _setupPoolRoles();
        _setupSettingManagerRoles();
        _setupVaultRoles();
        _setupTokenizationRoles();
        _setupStakingRouterRoles();
        vm.stopPrank();
    }

    function _setupPoolRoles() internal {
        coreContracts.accessManager.labelRole(
            Roles.POOL_INIT_RESERVE_ROLE,
            Roles.POOL_INIT_RESERVE_ROLE_NAME
        );
        coreContracts.accessManager.grantRole(
            Roles.POOL_INIT_RESERVE_ROLE,
            poolAdmin, // grant role to a EOA pool admin
            0
        );
        coreContracts.accessManager.grantRole(
            Roles.POOL_INIT_RESERVE_ROLE,
            address(coreContracts.settingManager), // grant role to setting manager
            0
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(coreContracts.pool),
            Roles.getPoolSelectors(),
            Roles.POOL_INIT_RESERVE_ROLE
        );
    }

    function _setupSettingManagerRoles() internal {
        coreContracts.accessManager.labelRole(
            Roles.SETTING_MANAGER_ADMIN_ROLE,
            Roles.SETTING_MANAGER_ADMIN_ROLE_NAME
        );
        coreContracts.accessManager.grantRole(
            Roles.SETTING_MANAGER_ADMIN_ROLE,
            settingManagerAdmin, // grant role to a EOA setting manager admin
            0
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(coreContracts.settingManager),
            Roles.getSettingManagerSelectors(),
            Roles.SETTING_MANAGER_ADMIN_ROLE
        );
    }

    function _setupVaultRoles() internal {
        coreContracts.accessManager.labelRole(
            Roles.VAULT_SETUP_ROLE,
            Roles.VAULT_SETUP_ROLE_NAME
        );
        coreContracts.accessManager.grantRole(
            Roles.VAULT_SETUP_ROLE,
            address(vaultAdmin),
            0
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(vaultContracts.vaultETH),
            Roles.getVaultSetupSelectors(),
            Roles.VAULT_SETUP_ROLE
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(vaultContracts.vaultLINK),
            Roles.getVaultSetupSelectors(),
            Roles.VAULT_SETUP_ROLE
        );

        coreContracts.accessManager.labelRole(
            Roles.VAULT_LOCK_COLLATERAL_ROLE,
            Roles.VAULT_LOCK_COLLATERAL_ROLE_NAME
        );
        coreContracts.accessManager.grantRole(
            Roles.VAULT_LOCK_COLLATERAL_ROLE,
            address(coreContracts.pool),
            0
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(vaultContracts.vaultETH),
            Roles.getVaultLockCollateralSelectors(),
            Roles.VAULT_LOCK_COLLATERAL_ROLE
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(vaultContracts.vaultLINK),
            Roles.getVaultLockCollateralSelectors(),
            Roles.VAULT_LOCK_COLLATERAL_ROLE
        );
    }

    function _setupTokenizationRoles() internal {
        coreContracts.accessManager.labelRole(
            Roles.MINTER_BURNER_ROLE,
            Roles.MINTER_BURNER_ROLE_NAME
        );
        coreContracts.accessManager.grantRole(
            Roles.MINTER_BURNER_ROLE,
            address(coreContracts.pool),
            0
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(tokenizationContracts.colETH),
            Roles.getMinterColTokenSelectors(),
            Roles.MINTER_BURNER_ROLE
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(tokenizationContracts.colLINK),
            Roles.getMinterColTokenSelectors(),
            Roles.MINTER_BURNER_ROLE
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(tokenizationContracts.colEUR),
            Roles.getMinterColEURSelectors(),
            Roles.MINTER_BURNER_ROLE
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(tokenizationContracts.debtEUR),
            Roles.getMinterDebtEURSelectors(),
            Roles.MINTER_BURNER_ROLE
        );
    }

    function _setupStakingRouterRoles() internal {
        coreContracts.accessManager.labelRole(
            Roles.ROUTER_ETH_VAULT_ROLE,
            Roles.ROUTER_ETH_VAULT_ROLE_NAME
        );
        coreContracts.accessManager.grantRole(
            Roles.ROUTER_ETH_VAULT_ROLE,
            address(vaultContracts.vaultETH),
            0
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(stakingRouters.stakingRouterETHLido),
            Roles.getRouterETHVaultSelectors(),
            Roles.ROUTER_ETH_VAULT_ROLE
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(stakingRouters.stakingRouterETHMorpho),
            Roles.getRouterETHVaultSelectors(),
            Roles.ROUTER_ETH_VAULT_ROLE
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(stakingRouters.stakingRouterETHEtherfi),
            Roles.getRouterETHVaultSelectors(),
            Roles.ROUTER_ETH_VAULT_ROLE
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(stakingRouters.stakingRouterETHRocketPool),
            Roles.getRouterETHVaultSelectors(),
            Roles.ROUTER_ETH_VAULT_ROLE
        );

        coreContracts.accessManager.labelRole(
            Roles.ROUTER_LINK_VAULT_ROLE,
            Roles.ROUTER_LINK_VAULT_ROLE_NAME
        );
        coreContracts.accessManager.grantRole(
            Roles.ROUTER_LINK_VAULT_ROLE,
            address(vaultContracts.vaultLINK),
            0
        );
        coreContracts.accessManager.setTargetFunctionRole(
            address(stakingRouters.stakingRouterLINK),
            Roles.getRouterLinkVaultSelectors(),
            Roles.ROUTER_LINK_VAULT_ROLE
        );
    }

    function _setupETHConfiguration() internal {
        address ethAddress = ETH_ADDRESS;

        IPool.CollateralConfiguration memory ethConfig = IPool
            .CollateralConfiguration({
                ltv: 8000, // 80%
                liquidationThreshold: 8500, // 85%
                liquidationBonus: 10500, // 105%
                liquidationProtocolFee: 1000, // 10%
                reserveFactor: 1000, // 10%
                supplyCap: 1000000 ether, // 1M ETH
                borrowCap: 800000 ether, // 800k ETH
                colToken: address(tokenizationContracts.colETH),
                tokenVault: address(vaultContracts.vaultETH),
                isFrozen: false,
                isPaused: false
            });

        coreContracts.pool.initCollateralAsset(ethAddress, ethConfig);
    }

    function _setupLINKConfiguration() internal {
        IPool.CollateralConfiguration memory linkConfig = IPool
            .CollateralConfiguration({
                ltv: 7000, // 70%
                liquidationThreshold: 7500, // 75%
                liquidationBonus: 11000, // 110%
                liquidationProtocolFee: 1000, // 10%
                reserveFactor: 1000, // 10%
                supplyCap: 100000 ether, // 100k LINK
                borrowCap: 70000 ether, // 70k LINK
                colToken: address(tokenizationContracts.colLINK),
                tokenVault: address(vaultContracts.vaultLINK),
                isFrozen: false,
                isPaused: false
            });

        coreContracts.pool.initCollateralAsset(
            address(mockContracts.linkToken),
            linkConfig
        );
    }

    function _setupEURConfiguration() internal {
        IPool.DebtConfiguration memory eurConfig = IPool.DebtConfiguration({
            supplyCap: 1000000000 * EURC_PRECISION, // 1B EURC
            borrowCap: 800000000 * EURC_PRECISION, // 800M EURC
            reserveFactor: 1000, // 10%
            colToken: address(tokenizationContracts.colEUR),
            debtToken: address(tokenizationContracts.debtEUR),
            isFrozen: false,
            isPaused: false
        });

        coreContracts.pool.initDebtAsset(
            address(mockContracts.eurToken),
            eurConfig
        );
    }

    function _setupVaultRouters() internal {
        vm.startPrank(vaultAdmin);
        // Setup ETH vault with staking routers
        vaultContracts.vaultETH.addStakingRouter(
            address(stakingRouters.stakingRouterETHLido)
        );
        vaultContracts.vaultETH.addStakingRouter(
            address(stakingRouters.stakingRouterETHEtherfi)
        );
        vaultContracts.vaultETH.addStakingRouter(
            address(stakingRouters.stakingRouterETHRocketPool)
        );
        vaultContracts.vaultETH.addStakingRouter(
            address(stakingRouters.stakingRouterETHMorpho)
        );

        // Set Lido as the current staking/unstaking router
        vaultContracts.vaultETH.updateCurrentStakingRouter(
            address(stakingRouters.stakingRouterETHLido)
        );
        vaultContracts.vaultETH.updateCurrentUnstakingRouter(
            address(stakingRouters.stakingRouterETHLido)
        );

        // Setup LINK vault with staking router
        vaultContracts.vaultLINK.addStakingRouter(
            address(stakingRouters.stakingRouterLINK)
        );
        vaultContracts.vaultLINK.updateCurrentStakingRouter(
            address(stakingRouters.stakingRouterLINK)
        );
        vaultContracts.vaultLINK.updateCurrentUnstakingRouter(
            address(stakingRouters.stakingRouterLINK)
        );
        vm.stopPrank();
    }

    // Helper functions for tests
    function getDeployedContracts()
        external
        view
        returns (
            CoreContracts memory,
            TokenizationContracts memory,
            VaultContracts memory,
            StakingRouters memory,
            MockContracts memory
        )
    {
        return (
            coreContracts,
            tokenizationContracts,
            vaultContracts,
            stakingRouters,
            mockContracts
        );
    }

    function setupUserWithTokens(
        address user,
        uint256 ethAmount,
        uint256 linkAmount,
        uint256 eurAmount
    ) external {
        // Give user ETH
        vm.deal(user, ethAmount);

        // Mint tokens to user
        mockContracts.linkToken.mint(user, linkAmount);
        mockContracts.eurToken.mint(user, eurAmount);
    }
}
