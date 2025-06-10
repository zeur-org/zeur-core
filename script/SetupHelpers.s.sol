// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";

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

// Interfaces
import {IPool} from "../src/interfaces/pool/IPool.sol";
import {IChainlinkOracleManager} from "../src/interfaces/chainlink/IChainlinkOracleManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SetupHelpers is Script {
    address initialAdmin = vm.envAddress("INITIAL_ADMIN");
    address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");

    address lidoStETH = vm.envAddress("LIDO_STETH");
    address lidoWithdrawQueue = vm.envAddress("LIDO_WITHDRAWQUEUE");

    address etherfiETH = vm.envAddress("ETHERFI_EETH");
    address etherfiPool = vm.envAddress("ETHERFI_POOL");

    address rocketRETH = vm.envAddress("ROCKET_RETH");
    address rocketPool = vm.envAddress("ROCKET_POOL");
    address rocketProtocolSetting = vm.envAddress("ROCKET_PROTOCOL_SETTING");

    address morphoETH = vm.envAddress("MORPHO_ETH");

    address link = vm.envAddress("LINK_TOKEN");
    address stLink = vm.envAddress("STAKELINK_STLINK");
    address priorityPool = vm.envAddress("STAKELINK_PRIORITY_POOL");

    address oracleManager = vm.envAddress("ORACLE_MANAGER");
    address pool = vm.envAddress("POOL");

    string colEURName = vm.envString("COLEUR_NAME");
    string colEURSymbol = vm.envString("COLEUR_SYMBOL");

    struct CoreContracts {
        Pool pool;
        PoolData poolData;
        ProtocolAccessManager accessManager;
        ProtocolSettingManager settingManager;
        ProtocolVaultManager vaultManager;
    }

    struct StakingRouters {
        StakingRouterLINK stakingRouterLINK;
        StakingRouterETHLido stakingRouterETHLido;
        StakingRouterETHMorpho stakingRouterETHMorpho;
        StakingRouterETHEtherfi stakingRouterETHEtherfi;
        StakingRouterETHRocketPool stakingRouterETHRocketPool;
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

    struct MockContracts {
        MockChainlinkOracleManager oracleManager;
        MockERC20 linkToken;
        MockERC20 stLinkToken;
        MockERC20 eurToken;
        MockPriorityPool linkPriorityPool;
        MockLido stETH;
        MockWithdrawalQueue withdrawalQueue;
        MockMorphoVault morphoVault;
        MockWETH wETH;
        MockRETH rETH;
        MockRocketDepositPool rocketDepositPool;
        MockRocketDAOSettings rocketDAOSettings;
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

    function deployAll() public returns (CoreContracts memory) {
        vm.startBroadcast();

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

        vm.stopBroadcast();

        return coreContracts;
    }

    function _deployMockContracts() internal {
        // Deploy mock tokens
        mockContracts.linkToken = new MockERC20("Chainlink Token", "LINK");
        mockContracts.stLinkToken = new MockERC20("Staked LINK", "stLINK");
        mockContracts.eurToken = new MockERC20("Euro Token", "EUR");

        // Deploy mock external protocol contracts
        mockContracts.oracleManager = new MockChainlinkOracleManager();
        mockContracts.linkPriorityPool = new MockPriorityPool();
        mockContracts.stETH = new MockLido();
        mockContracts.withdrawalQueue = new MockWithdrawalQueue();
        mockContracts.wETH = new MockWETH();
        mockContracts.morphoVault = new MockMorphoVault(
            address(mockContracts.wETH)
        );
        mockContracts.rETH = new MockRETH();
        mockContracts.rocketDepositPool = new MockRocketDepositPool();
        mockContracts.rocketDAOSettings = new MockRocketDAOSettings();

        // Set proper asset prices
        mockContracts.oracleManager.setAssetPrice(
            address(mockContracts.linkToken),
            1500000000
        ); // $15
        mockContracts.oracleManager.setAssetPrice(
            address(mockContracts.eurToken),
            110000000
        ); // $1.10

        console.log("Mock contracts deployed");
    }

    function _deployAccessManager() internal {
        address protocolAccessManagerProxy = Upgrades.deployUUPSProxy(
            "ProtocolAccessManager.sol",
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
        address poolProxy = Upgrades.deployUUPSProxy(
            "Pool.sol",
            abi.encodeWithSelector(
                Pool.initialize.selector,
                initialAuthority,
                oracleManager
            )
        );

        coreContracts.pool = Pool(address(poolProxy));

        console.log("Pool deployed at:", address(coreContracts.pool));
    }

    function _deployPoolData() internal {
        address poolDataProxy = Upgrades.deployUUPSProxy(
            "PoolData.sol",
            abi.encodeWithSelector(
                PoolData.initialize.selector,
                initialAuthority,
                pool,
                oracleManager
            )
        );

        coreContracts.poolData = PoolData(address(poolDataProxy));

        console.log("PoolData deployed at:", address(coreContracts.poolData));
    }

    function _deployManagers() internal {
        // Deploy ProtocolSettingManager
        address protocolSettingManagerProxy = Upgrades.deployUUPSProxy(
            "ProtocolSettingManager.sol",
            abi.encodeWithSelector(
                ProtocolSettingManager.initialize.selector,
                initialAuthority,
                pool
            )
        );

        coreContracts.settingManager = ProtocolSettingManager(
            address(protocolSettingManagerProxy)
        );

        // Deploy ProtocolVaultManager
        address protocolVaultManagerProxy = Upgrades.deployUUPSProxy(
            "ProtocolVaultManager.sol",
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
        // Deploy ColEUR
        address colEURProxy = Upgrades.deployUUPSProxy(
            "ColEUR.sol",
            abi.encodeWithSelector(
                ColEUR.initialize.selector,
                address(coreContracts.accessManager),
                IERC20(address(mockContracts.eurToken)),
                colEURName,
                colEURSymbol
            )
        );

        tokenizationContracts.colEUR = ColEUR(address(colEURProxy));

        // Deploy ColTokens
        address colETHProxy = Upgrades.deployUUPSProxy(
            "ColToken.sol",
            abi.encodeWithSelector(
                ColToken.initialize.selector,
                address(coreContracts.accessManager),
                "Collateral ETH",
                "colETH"
            )
        );

        tokenizationContracts.colLINK = ColToken(address(colETHProxy));

        address colLINKProxy = Upgrades.deployUUPSProxy(
            "ColToken.sol",
            abi.encodeWithSelector(
                ColToken.initialize.selector,
                address(coreContracts.accessManager),
                "Collateral LINK",
                "colLINK"
            )
        );

        tokenizationContracts.colLINK = ColToken(address(colLINKProxy));

        // Deploy DebtEUR
        address debtEURProxy = Upgrades.deployUUPSProxy(
            "DebtEUR.sol",
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
        address vaultETHProxy = Upgrades.deployUUPSProxy(
            "VaultETH.sol",
            abi.encodeWithSelector(
                VaultETH.initialize.selector,
                address(coreContracts.accessManager)
            )
        );

        vaultContracts.vaultETH = VaultETH(payable(address(vaultETHProxy)));

        // Deploy VaultLINK
        address vaultLINKProxy = Upgrades.deployUUPSProxy(
            "VaultLINK.sol",
            abi.encodeWithSelector(
                VaultLINK.initialize.selector,
                address(coreContracts.accessManager)
            )
        );

        vaultContracts.vaultLINK = VaultLINK(address(vaultLINKProxy));

        console.log("Vaults deployed");
    }

    function _deployStakingRouters() internal {
        address lidoRouterProxy = Upgrades.deployUUPSProxy(
            "StakingRouterETHLido.sol",
            abi.encodeWithSelector(
                StakingRouterETHLido.initialize.selector,
                initialAuthority,
                lidoStETH,
                lidoWithdrawQueue
            )
        );

        stakingRouters.stakingRouterETHLido = StakingRouterETHLido(
            address(lidoRouterProxy)
        );

        address etherfiRouterProxy = Upgrades.deployUUPSProxy(
            "StakingRouterETHEtherfi.sol",
            abi.encodeWithSelector(
                StakingRouterETHEtherfi.initialize.selector,
                initialAuthority
            )
        );

        stakingRouters.stakingRouterETHEtherfi = StakingRouterETHEtherfi(
            address(etherfiRouterProxy)
        );

        address rocketRouterProxy = Upgrades.deployUUPSProxy(
            "StakingRouterETHRocketPool.sol",
            abi.encodeWithSelector(
                StakingRouterETHRocketPool.initialize.selector,
                initialAuthority,
                rocketRETH,
                rocketPool,
                rocketProtocolSetting
            )
        );

        stakingRouters.stakingRouterETHRocketPool = StakingRouterETHRocketPool(
            address(rocketRouterProxy)
        );

        address morphoRouterProxy = Upgrades.deployUUPSProxy(
            "StakingRouterETHMorpho.sol",
            abi.encodeWithSelector(
                StakingRouterETHMorpho.initialize.selector,
                initialAuthority,
                morphoETH,
                mockContracts.morphoVault
            )
        );

        stakingRouters.stakingRouterETHMorpho = StakingRouterETHMorpho(
            address(morphoRouterProxy)
        );

        address stakingRouterLINKProxy = Upgrades.deployUUPSProxy(
            "StakingRouterLINK.sol",
            abi.encodeWithSelector(
                StakingRouterLINK.initialize.selector,
                initialAuthority,
                stLink,
                link,
                priorityPool
            )
        );

        stakingRouters.stakingRouterLINK = StakingRouterLINK(
            address(stakingRouterLINKProxy)
        );

        console.log("Staking routers deployed");
    }

    function _setupInitialConfigurations() internal {
        // Setup asset configurations in the pool
        _setupETHConfiguration();
        _setupLINKConfiguration();
        _setupEURConfiguration();

        // Setup vault staking routers
        _setupVaultRouters();

        console.log("Initial configurations set up");
    }

    function _setupETHConfiguration() internal {
        address ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        IPool.CollateralConfiguration memory ethConfig = IPool
            .CollateralConfiguration({
                ltv: 8000, // 80%
                liquidationThreshold: 8500, // 85%
                liquidationBonus: 500, // 5%
                liquidationProtocolFee: 1000, // 10%
                reserveFactor: 1000, // 10%
                supplyCap: 1000000 ether,
                borrowCap: 800000 ether,
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
                liquidationBonus: 500, // 5%
                liquidationProtocolFee: 1000, // 10%
                reserveFactor: 1000, // 10%
                supplyCap: 100000 ether,
                borrowCap: 70000 ether,
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
            supplyCap: 10000000 ether, // 10M EUR
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
        // Setup ETH vault with staking routers
        vaultContracts.vaultETH.addStakingRouter(
            address(stakingRouters.stakingRouterETHLido)
        );
        vaultContracts.vaultETH.addStakingRouter(
            address(stakingRouters.stakingRouterETHMorpho)
        );
        vaultContracts.vaultETH.addStakingRouter(
            address(stakingRouters.stakingRouterETHRocketPool)
        );
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
    }

    // Helper functions for tests
    function getDeployedContracts()
        external
        view
        returns (CoreContracts memory)
    {
        return coreContracts;
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

// Mock contracts for testing
contract MockChainlinkOracleManager {
    mapping(address => uint256) public prices;

    constructor() {
        // Set default prices (8 decimals, like Chainlink)
        prices[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = 200000000000; // ETH: $2000
    }

    function getAssetPrice(address asset) external view returns (uint256) {
        return prices[asset];
    }

    function setAssetPrice(address asset, uint256 price) external {
        prices[asset] = price;
    }
}

contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

contract MockPriorityPool {
    function deposit(
        uint256 amount,
        bool shouldQueue,
        bytes[] calldata data
    ) external {}

    function withdraw(
        uint256 amount,
        uint256 amountOut,
        uint256 sharesOut,
        bytes32[] calldata proof,
        bool shouldUnqueue,
        bool shouldQueueWithdrawal,
        bytes[] calldata data
    ) external {}
}

contract MockLido {
    function submit(address referral) external payable returns (uint256) {
        return msg.value; // 1:1 for simplicity
    }
}

contract MockWithdrawalQueue {
    function requestWithdrawals(
        uint256[] calldata amounts,
        address owner
    ) external returns (uint256[] memory) {
        uint256[] memory requestIds = new uint256[](amounts.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            requestIds[i] = i + 1;
        }
        return requestIds;
    }

    function claimWithdrawal(uint256 requestId) external {}
}

contract MockWETH {
    function deposit() external payable {}

    function withdraw(uint256 amount) external {}

    function approve(address spender, uint256 amount) external returns (bool) {
        return true;
    }
}

contract MockMorphoVault {
    address public immutable asset;

    constructor(address _asset) {
        asset = _asset;
    }

    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256) {
        return assets; // 1:1 for simplicity
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256) {
        return assets;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return true;
    }
}

contract MockRETH {
    function getRethValue(uint256 ethAmount) external pure returns (uint256) {
        return (ethAmount * 95) / 100; // Simplified exchange rate
    }

    function getEthValue(uint256 rethAmount) external pure returns (uint256) {
        return (rethAmount * 100) / 95; // Inverse of above
    }

    function getExchangeRate() external pure returns (uint256) {
        return 1050000000000000000; // 1.05 ETH per rETH
    }

    function burn(uint256 amount) external {}

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        return true;
    }
}

contract MockRocketDepositPool {
    function deposit() external payable {}
}

contract MockRocketDAOSettings {
    function getDepositFee() external pure returns (uint256) {
        return 5000000000000000; // 0.5%
    }
}
