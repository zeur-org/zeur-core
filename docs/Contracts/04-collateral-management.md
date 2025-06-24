# ZEUR Collateral Management

## Overview

The ZEUR protocol implements a sophisticated collateral management system that ensures protocol safety while maximizing capital efficiency. The system supports multiple collateral types, dynamic risk parameters, and automated staking to generate yield on deposited assets.

## Supported Collateral Assets

### ETH (Ethereum)

- **Symbol**: ETH
- **Type**: Native cryptocurrency
- **Decimals**: 18
- **Staking**: Automatic across multiple LST protocols
- **Yield**: Ethereum staking rewards (~3-5% APR)

### LINK (Chainlink)

- **Symbol**: LINK
- **Type**: ERC20 token
- **Decimals**: 18
- **Staking**: Via StakeLink protocol
- **Yield**: LINK staking rewards (~4-7% APR)

## Collateral Configuration

Each collateral asset has a comprehensive configuration that determines its risk parameters and operational limits:

```solidity
struct CollateralConfiguration {
    uint256 supplyCap;              // Maximum total supply allowed
    uint256 borrowCap;              // Maximum borrowing against this collateral
    address colToken;               // Associated colToken contract
    address tokenVault;             // Associated vault contract
    uint16 ltv;                     // Loan-to-value ratio (basis points)
    uint16 liquidationThreshold;    // Liquidation threshold (basis points)
    uint16 liquidationBonus;        // Liquidation bonus (basis points)
    uint16 liquidationProtocolFee;  // Protocol fee on liquidations (basis points)
    uint16 reserveFactor;           // Reserve factor for protocol (basis points)
    bool isFrozen;                  // Frozen state flag
    bool isPaused;                  // Paused state flag
}
```

### Example Configurations

#### ETH Configuration

```solidity
CollateralConfiguration({
    supplyCap: 1000000 ether,           // 1M ETH max supply
    borrowCap: 800000 ether,            // 800K ETH max borrow backing
    colToken: address(colETH),          // colETH token address
    tokenVault: address(vaultETH),      // ETH vault address
    ltv: 8000,                         // 80% LTV
    liquidationThreshold: 8500,         // 85% liquidation threshold
    liquidationBonus: 10500,            // 105% (5% bonus to liquidators)
    liquidationProtocolFee: 1000,       // 10% of liquidation bonus to protocol
    reserveFactor: 1000,                // 10% reserve factor
    isFrozen: false,                    // Active
    isPaused: false                     // Active
})
```

#### LINK Configuration

```solidity
CollateralConfiguration({
    supplyCap: 100000 ether,            // 100K LINK max supply
    borrowCap: 70000 ether,             // 70K LINK max borrow backing
    colToken: address(colLINK),         // colLINK token address
    tokenVault: address(vaultLINK),     // LINK vault address
    ltv: 7000,                         // 70% LTV (more conservative)
    liquidationThreshold: 7500,         // 75% liquidation threshold
    liquidationBonus: 11000,            // 110% (10% bonus to liquidators)
    liquidationProtocolFee: 1000,       // 10% of liquidation bonus to protocol
    reserveFactor: 1000,                // 10% reserve factor
    isFrozen: false,                    // Active
    isPaused: false                     // Active
})
```

## Risk Parameters

### 1. Loan-to-Value (LTV) Ratio

The LTV ratio determines the maximum borrowing power against collateral:

```
Max Borrow Value = Collateral Value × LTV
```

**Example:**

- User deposits $10,000 worth of ETH (80% LTV)
- Maximum borrowing capacity: $10,000 × 0.80 = $8,000

**LTV Considerations:**

- **ETH**: 80% (high confidence in ETH stability)
- **LINK**: 70% (slightly more volatile than ETH)
- **Buffer**: LTV < Liquidation Threshold for safety margin

### 2. Liquidation Threshold

The liquidation threshold determines when a position becomes liquidatable:

```
Health Factor = (Collateral Value × Liquidation Threshold) / Debt Value
```

When Health Factor < 1.0, liquidation is triggered.

**Example:**

- User has $10,000 ETH collateral (85% threshold)
- User has $8,500 debt
- Health Factor = ($10,000 × 0.85) / $8,500 = 1.0
- Position is at liquidation threshold

### 3. Liquidation Bonus

The liquidation bonus incentivizes liquidators to maintain protocol health:

```
Collateral Seized = (Debt Repaid × Liquidation Bonus) / Collateral Price
```

**Example:**

- Liquidator repays $1,000 debt
- ETH liquidation bonus: 5%
- Collateral received: $1,000 × 1.05 = $1,050 worth of ETH

### 4. Supply and Borrow Caps

Caps limit protocol exposure to any single asset:

**Supply Cap**: Maximum total amount that can be deposited

- Prevents over-concentration in any asset
- Limits protocol exposure to asset-specific risks

**Borrow Cap**: Maximum borrowing backed by this collateral type

- Controls leverage on volatile assets
- Manages liquidity requirements

## Health Factor Calculation

The health factor is the primary metric for position safety:

### Single Collateral

```
Health Factor = (Collateral Value × Liquidation Threshold) / Debt Value
```

### Multiple Collateral Assets

```
Weighted Liquidation Threshold = Σ(Collateral_Value_i × Threshold_i) / Total_Collateral_Value
Health Factor = (Total_Collateral_Value × Weighted_Threshold) / Total_Debt_Value
```

### Health Factor Interpretation

- **> 1.5**: Very safe position
- **1.1 - 1.5**: Safe position
- **1.0 - 1.1**: Risky position, close to liquidation
- **< 1.0**: Liquidatable position

## Collateral Operations

### 1. Supply Collateral

```solidity
function supply(address asset, uint256 amount, address from) external payable;
```

**Process:**

1. **Validation**: Check asset is allowed and not paused
2. **Transfer**: Move asset to appropriate vault
3. **Staking**: Vault automatically stakes asset
4. **Tokenization**: Mint colToken 1:1 with deposit
5. **Tracking**: Update user's collateral balance

**Example:**

```solidity
// Supply 5 ETH as collateral
pool.supply{value: 5 ether}(ETH_ADDRESS, 5 ether, user);
```

### 2. Withdraw Collateral

```solidity
function withdraw(address asset, uint256 amount, address to) external;
```

**Process:**

1. **Health Check**: Ensure health factor remains > 1.0 after withdrawal
2. **Burn Tokens**: Burn user's colTokens
3. **Unstaking**: Unstake assets from LST protocols
4. **Transfer**: Send unstaked assets to user

**Safety Checks:**

```solidity
UserAccountData memory userData = getUserAccountData(msg.sender);
require(userData.healthFactor >= HEALTH_FACTOR_BASE, "Insufficient health factor");
```

### 3. Liquidation

When a position becomes unhealthy (health factor < 1), it can be liquidated:

```solidity
function liquidate(
    address collateralAsset,
    address debtAsset,
    uint256 debtAmount,
    address from
) external;
```

**Liquidation Process:**

1. **Health Check**: Verify position is liquidatable
2. **Amount Limits**: Max 50% of debt can be liquidated per transaction
3. **Bonus Calculation**: Calculate collateral to seize with bonus
4. **Execution**: Repay debt, seize collateral
5. **Distribution**: Send collateral to liquidator

## Asset State Management

### Asset States

Assets can be in different operational states:

#### 1. Active State

- **Supply**: ✅ Allowed
- **Withdraw**: ✅ Allowed
- **Borrow Against**: ✅ Allowed
- **Liquidate**: ✅ Allowed

#### 2. Frozen State

- **Supply**: ❌ Blocked
- **Withdraw**: ✅ Allowed
- **Borrow Against**: ❌ Blocked
- **Liquidate**: ✅ Allowed

#### 3. Paused State

- **Supply**: ❌ Blocked
- **Withdraw**: ❌ Blocked
- **Borrow Against**: ❌ Blocked
- **Liquidate**: ❌ Blocked

### State Transitions

```solidity
// Protocol admin can change asset states
function freezeCollateral(address asset, bool freeze) external restricted;
function pauseCollateral(address asset, bool pause) external restricted;
```

## Automatic Staking Integration

### ETH Staking

ETH collateral automatically stakes across multiple protocols:

```
User ETH → VaultETH → Distribution → Multiple LSTs
                   ├── Lido (stETH)
                   ├── RocketPool (rETH)
                   ├── EtherFi (eETH)
                   └── Morpho (Vault)
```

**Benefits:**

- Diversified staking risk
- Optimized yields
- Automatic rebalancing
- No manual management required

### LINK Staking

LINK collateral stakes via StakeLink:

```
User LINK → VaultLINK → StakeLink → stLINK Rewards
```

**Benefits:**

- Native LINK staking yields
- Simplified staking process
- Automatic reward compounding

## Risk Management Features

### 1. Diversification

- Multiple LST protocols reduce concentration risk
- Asset-specific caps limit exposure
- Cross-collateral support spreads risk

### 2. Dynamic Parameters

- Risk parameters can be updated by governance
- Market conditions influence parameter changes
- Gradual parameter changes prevent market shock

### 3. Circuit Breakers

- Pause functionality for emergency situations
- Freeze functionality for risk mitigation
- Oracle-based price protection

### 4. Liquidation Incentives

- Competitive liquidation bonuses
- Protocol fees support sustainability
- Partial liquidation limits prevent over-liquidation

## Collateral Valuation

### Price Sources

All collateral valuations use Chainlink oracles:

```solidity
interface IChainlinkOracleManager {
    function getAssetPrice(address asset) external view returns (uint256);
}
```

### Valuation Formula

```solidity
function calculateCollateralValue(address user, address asset) internal view returns (uint256) {
    uint256 balance = IERC20(colToken).balanceOf(user);
    uint256 price = oracleManager.getAssetPrice(asset);
    uint256 decimals = IERC20Metadata(asset).decimals();

    return (balance * price) / 10**decimals;
}
```

### Multi-Asset Portfolios

For users with multiple collateral types:

```solidity
function getTotalCollateralValue(address user) internal view returns (uint256) {
    uint256 totalValue = 0;
    address[] memory assets = getCollateralAssetList();

    for (uint256 i = 0; i < assets.length; i++) {
        totalValue += calculateCollateralValue(user, assets[i]);
    }

    return totalValue;
}
```

## Gas Optimization

### Efficient Operations

- Batch liquidations for multiple assets
- Optimized storage layouts
- Minimal external calls

### Staking Efficiency

- Automated distribution across LSTs
- Optimal gas usage for staking operations
- Batch unstaking when possible

The collateral management system ensures that ZEUR protocol maintains safety while maximizing capital efficiency through automated staking and careful risk parameter management.
