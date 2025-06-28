# Vault System and Liquid Staking Integration

## Overview

The ZEUR vault system automatically stakes deposited collateral across multiple liquid staking token (LST) protocols to maximize yield while maintaining liquidity. This innovative approach allows users to earn staking rewards on their collateral while simultaneously using it for borrowing, significantly improving capital efficiency.

## Vault Architecture

### VaultETH (Ethereum Vault)

The ETH vault manages Ethereum deposits and distributes them across multiple LST protocols:

```solidity
contract VaultETH is AccessManagedUpgradeable, UUPSUpgradeable, IVault {
    // Staking routers for different LST protocols
    mapping(address => bool) public stakingRouters;

    // Track staked amounts per protocol
    mapping(address => uint256) public stakedAmounts;
}
```

**Supported LST Protocols:**

- **Lido**: stETH integration
- **RocketPool**: rETH integration
- **EtherFi**: eETH integration
- **Morpho**: Morpho vault integration

### VaultLINK (Chainlink Vault)

The LINK vault manages LINK token deposits and stakes them via StakeLink:

```solidity
contract VaultLINK is AccessManagedUpgradeable, UUPSUpgradeable, IVault {
    // StakeLink integration
    IStakeLink public stakeLink;

    // Track stLINK holdings
    uint256 public totalStakedLINK;
}
```

**Supported Staking:**

- **StakeLink**: stLINK integration

## Staking Router System

### Router Architecture

Each LST protocol has a dedicated staking router that handles protocol-specific interactions:

```
VaultETH
├── StakingRouterETHLido
├── StakingRouterETHRocketPool
├── StakingRouterETHEtherfi
└── StakingRouterETHMorpho

VaultLINK
└── StakingRouterLINK
```

### Router Interface

All staking routers implement a common interface:

```solidity
interface IStakingRouter {
    function stake(address from, uint256 amount) external;
    function unstake(address to, uint256 amount) external;
    function getStakedBalance() external view returns (uint256);
    function getUnderlyingBalance() external view returns (uint256);
}
```

## ETH Staking Integration

### 1. Lido Integration (stETH)

**StakingRouterETHLido** manages stETH staking:

```solidity
contract StakingRouterETHLido is AccessManagedUpgradeable, UUPSUpgradeable {
    ILido public lido;
    IERC20 public stETH;

    function stake(address from, uint256 amount) external {
        // Stake ETH with Lido to receive stETH
        uint256 stETHReceived = lido.submit{value: amount}(address(0));

        // Track stETH balance
        emit Staked(from, amount, stETHReceived);
    }

    function unstake(address to, uint256 amount) external {
        // Request withdrawal from Lido
        // Handle stETH -> ETH conversion
        lido.requestWithdrawals([amount], [address(this)]);
    }
}
```

**Key Features:**

- Automatic stETH accumulation
- Withdrawal queue management
- Rebase token handling

### 2. RocketPool Integration (rETH)

**StakingRouterETHRocketPool** manages rETH staking:

```solidity
contract StakingRouterETHRocketPool is AccessManagedUpgradeable, UUPSUpgradeable {
    IRocketDepositPool public rocketDepositPool;
    IERC20 public rETH;

    function stake(address from, uint256 amount) external {
        // Deposit ETH to RocketPool
        rocketDepositPool.deposit{value: amount}();

        // Receive rETH tokens
        uint256 rETHBalance = rETH.balanceOf(address(this));
        emit Staked(from, amount, rETHBalance);
    }

    function unstake(address to, uint256 amount) external {
        // Burn rETH for ETH
        IRocketTokenRETH(address(rETH)).burn(amount);

        // Transfer ETH to user
        payable(to).transfer(amount);
    }
}
```

**Key Features:**

- Direct ETH deposits
- rETH exchange rate handling
- Instant liquidity via rETH/ETH trading

### 3. EtherFi Integration (eETH)

**StakingRouterETHEtherfi** manages eETH staking:

```solidity
contract StakingRouterETHEtherfi is AccessManagedUpgradeable, UUPSUpgradeable {
    IEtherFi public etherFi;
    IERC20 public eETH;

    function stake(address from, uint256 amount) external {
        // Deposit ETH to EtherFi
        uint256 eETHReceived = etherFi.depositToEtherFiNode{value: amount}();

        emit Staked(from, amount, eETHReceived);
    }

    function unstake(address to, uint256 amount) external {
        // Request withdrawal from EtherFi
        etherFi.requestWithdraw(address(this), amount);
    }
}
```

**Key Features:**

- Native restaking integration
- Eigenlayer compatibility
- Enhanced yields through restaking

### 4. Morpho Integration

**StakingRouterETHMorpho** manages Morpho vault deposits:

```solidity
contract StakingRouterETHMorpho is AccessManagedUpgradeable, UUPSUpgradeable {
    IMorphoVault public morphoVault;

    function stake(address from, uint256 amount) external {
        // Deposit ETH to Morpho vault
        uint256 shares = morphoVault.deposit{value: amount}(amount, address(this));

        emit Staked(from, amount, shares);
    }

    function unstake(address to, uint256 amount) external {
        // Withdraw from Morpho vault
        morphoVault.withdraw(amount, to, address(this));
    }
}
```

**Key Features:**

- Lending market yields
- Morpho optimization
- Variable rate returns

## LINK Staking Integration

### StakeLink Integration

**StakingRouterLINK** manages LINK staking via StakeLink:

```solidity
contract StakingRouterLINK is AccessManagedUpgradeable, UUPSUpgradeable {
    IStakeLink public stakeLink;
    IERC20 public linkToken;
    IERC20 public stLINK;

    function stake(address from, uint256 amount) external {
        // Approve LINK to StakeLink
        linkToken.approve(address(stakeLink), amount);

        // Stake LINK for stLINK
        stakeLink.stake(amount, false, new bytes[](0));

        uint256 stLINKReceived = stLINK.balanceOf(address(this));
        emit Staked(from, amount, stLINKReceived);
    }

    function unstake(address to, uint256 amount) external {
        // Unstake stLINK for LINK
        stakeLink.unstake(amount, 0, new bytes32[](0), false, false, new bytes[](0));

        // Transfer LINK to user
        linkToken.transfer(to, amount);
    }
}
```

**Key Features:**

- Native LINK staking rewards
- stLINK liquid staking token
- Withdrawal queue management

## Staking Strategy Management

### Distribution Strategy

The vault automatically distributes deposits across multiple protocols based on:

1. **Target Allocations**: Predefined percentages per protocol
2. **Yield Optimization**: Dynamic allocation based on returns
3. **Risk Management**: Diversification across protocols
4. **Liquidity Needs**: Maintain adequate unstaking capacity

### Example ETH Distribution

```solidity
struct AllocationStrategy {
    uint256 lidoTarget;      // 40% to Lido
    uint256 rocketTarget;    // 30% to RocketPool
    uint256 etherfiTarget;   // 20% to EtherFi
    uint256 morphoTarget;    // 10% to Morpho
}
```

### Rebalancing Logic

```solidity
function rebalance() external {
    // Calculate current allocations
    uint256 totalStaked = getTotalStaked();

    // Calculate target allocations
    AllocationStrategy memory targets = getAllocationTargets();

    // Rebalance if deviation > threshold
    if (needsRebalancing(targets)) {
        executeRebalancing(targets);
    }
}
```

## Vault Operations

### 1. Lock Collateral (Stake)

When users supply collateral:

```solidity
function lockCollateral(address from, uint256 amount) external payable {
    require(msg.sender == poolAddress, "Only pool can lock");

    if (address(this) == vaultETH) {
        // Distribute ETH across staking routers
        distributeToStakingRouters(amount);
    } else {
        // Handle LINK staking
        stakeLINK(amount);
    }

    emit CollateralLocked(from, amount);
}
```

### 2. Unlock Collateral (Unstake)

When users withdraw collateral:

```solidity
function unlockCollateral(address to, uint256 amount) external {
    require(msg.sender == poolAddress, "Only pool can unlock");

    // Unstake from protocols to fulfill withdrawal
    unstakeFromProtocols(amount);

    // Transfer unstaked assets to user
    transferToUser(to, amount);

    emit CollateralUnlocked(to, amount);
}
```

### 3. Emergency Unstaking

For liquidations or urgent withdrawals:

```solidity
function emergencyUnstake(uint256 amount) external restricted {
    // Unstake from most liquid protocols first
    unstakeUrgent(amount);
}
```

## Yield Management

### Reward Collection

Staking rewards are automatically collected and managed:

```solidity
function collectRewards() external {
    uint256 totalRewards = 0;

    // Collect from all staking routers
    for (uint i = 0; i < stakingRouters.length; i++) {
        uint256 rewards = stakingRouters[i].collectRewards();
        totalRewards += rewards;
    }

    // Distribute rewards (compound or distribute)
    distributeRewards(totalRewards);
}
```

### Reward Distribution

Options for reward handling:

1. **Auto-Compound**: Automatically restake rewards
2. **Protocol Fee**: Take percentage for protocol treasury
3. **User Distribution**: Distribute proportionally to depositors

```solidity
function distributeRewards(uint256 totalRewards) internal {
    uint256 protocolFee = (totalRewards * reserveFactor) / 10000;
    uint256 userRewards = totalRewards - protocolFee;

    // Send protocol fee to treasury
    treasury.deposit(protocolFee);

    // Compound user rewards
    compoundRewards(userRewards);
}
```

## Liquidity Management

### Withdrawal Queue

For protocols with withdrawal delays:

```solidity
struct WithdrawalRequest {
    address user;
    uint256 amount;
    uint256 requestTime;
    address protocol;
    bool fulfilled;
}

mapping(uint256 => WithdrawalRequest) public withdrawalQueue;
```

### Liquidity Buffer

Maintain liquid reserves for immediate withdrawals:

```solidity
uint256 public liquidityBuffer = 5; // 5% of total deposits
uint256 public maxLiquidityBuffer = 10; // Maximum 10%

function maintainLiquidity() external {
    uint256 currentLiquidity = address(this).balance;
    uint256 targetLiquidity = (getTotalDeposits() * liquidityBuffer) / 100;

    if (currentLiquidity < targetLiquidity) {
        unstakeForLiquidity(targetLiquidity - currentLiquidity);
    }
}
```

## Integration Benefits

### For Users

1. **Passive Income**: Automatic staking rewards
2. **Diversification**: Risk spread across multiple protocols
3. **No Management**: Set-and-forget staking
4. **Liquidity**: Collateral remains borrowable

### For Protocol

1. **Yield Generation**: Additional revenue streams
2. **Competitive Advantage**: Higher effective APY
3. **Risk Mitigation**: Protocol diversification
4. **Capital Efficiency**: Productive use of idle assets

## Risk Management

### Protocol Risk Mitigation

1. **Diversification**: Multiple LST protocols
2. **Allocation Limits**: Maximum exposure per protocol
3. **Emergency Controls**: Pause and withdraw mechanisms
4. **Insurance Integration**: Slashing protection where available

### Slashing Risk Management

```solidity
struct SlashingInsurance {
    address provider;
    uint256 coverage;
    uint256 premium;
    bool active;
}

mapping(address => SlashingInsurance) public slashingInsurance;
```

### Monitoring and Alerts

```solidity
event StakingAnomalyDetected(address protocol, string reason);
event RewardsCollected(address protocol, uint256 amount);
event ProtocolPaused(address protocol, string reason);
```

## Gas Optimization

### Batch Operations

```solidity
function batchStake(
    address[] calldata protocols,
    uint256[] calldata amounts
) external {
    require(protocols.length == amounts.length, "Array mismatch");

    for (uint i = 0; i < protocols.length; i++) {
        IStakingRouter(protocols[i]).stake(msg.sender, amounts[i]);
    }
}
```

### Efficient Rebalancing

- Minimize number of transactions
- Optimize gas usage across protocols
- Batch reward collection and distribution

The vault system provides a sophisticated foundation for automated yield generation while maintaining the liquidity and composability required for the ZEUR lending protocol.
