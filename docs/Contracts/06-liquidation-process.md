# Liquidation Process

## Overview

The liquidation process is a critical safety mechanism that maintains protocol solvency by automatically liquidating undercollateralized positions. When a user's health factor falls below 1.0, liquidators can repay part of their debt in exchange for discounted collateral, ensuring the protocol remains properly collateralized.

## Liquidation Triggers

### Health Factor Threshold

Liquidation is triggered when a user's health factor drops below 1.0:

```
Health Factor = (Collateral Value × Liquidation Threshold) / Debt Value
```

**Liquidation Conditions:**

- Health Factor < 1.0: Position becomes liquidatable
- Health Factor ≥ 1.0: Position is safe from liquidation

### Example Liquidation Scenario

**Initial Position:**

- User deposits 10 ETH at $3,000 = $30,000 collateral
- ETH liquidation threshold: 85%
- User borrows $20,000 EURC
- Health Factor = ($30,000 × 0.85) / $20,000 = 1.275 (Safe)

**Price Drop Scenario:**

- ETH price drops to $2,400
- Collateral value: 10 ETH × $2,400 = $24,000
- Health Factor = ($24,000 × 0.85) / $20,000 = 1.02 (Risky)

**Further Price Drop:**

- ETH price drops to $2,300
- Collateral value: 10 ETH × $2,300 = $23,000
- Health Factor = ($23,000 × 0.85) / $20,000 = 0.978 (Liquidatable!)

## Liquidation Mechanics

### Function Signature

```solidity
function liquidate(
    address collateralAsset,    // Asset to seize (ETH, LINK)
    address debtAsset,          // Asset to repay (EURC)
    uint256 debtAmount,         // Amount of debt to repay
    address from                // User being liquidated
) external nonReentrant;
```

### Liquidation Process Flow

```
1. Liquidator calls liquidate()
2. Protocol validates liquidation conditions
3. Protocol calculates collateral to seize
4. Liquidator transfers debt tokens to protocol
5. Protocol burns debt tokens from user
6. Protocol transfers collateral to liquidator
7. User's position is improved
```

### Step-by-Step Process

#### 1. Validation Phase

```solidity
// Check assets are valid
require(collateralAssetList.contains(collateralAsset), "Invalid collateral");
require(debtAssetList.contains(debtAsset), "Invalid debt asset");

// Check assets not paused
require(!collateralConfig.isPaused, "Collateral paused");
require(!debtConfig.isPaused, "Debt asset paused");

// Verify user is liquidatable
UserAccountData memory userData = getUserAccountData(from);
require(userData.healthFactor < HEALTH_FACTOR_BASE, "Not liquidatable");
```

#### 2. Amount Calculation

```solidity
// Limit to 50% of user's debt for this asset
uint256 userDebtBalance = IERC20(debtToken).balanceOf(from);
uint256 maxLiquidatable = userDebtBalance / 2;
if (debtAmount > maxLiquidatable) {
    debtAmount = maxLiquidatable;
}
```

#### 3. Collateral Calculation

```solidity
// Get prices from oracle
uint256 debtPrice = oracleManager.getAssetPrice(debtAsset);
uint256 collateralPrice = oracleManager.getAssetPrice(collateralAsset);

// Calculate USD value of debt being repaid
uint256 debtValueUSD = (debtAmount * debtPrice) / 10**debtDecimals;

// Apply liquidation bonus
uint256 bonusValue = (debtValueUSD * liquidationBonus) / 10000;

// Convert to collateral amount
uint256 collateralAmount = (bonusValue * 10**collateralDecimals) / collateralPrice;
```

#### 4. Execution Phase

```solidity
// Transfer debt from liquidator to protocol
IERC20(debtAsset).safeTransferFrom(liquidator, colEUR, debtAmount);

// Burn debt tokens from liquidated user
IDebtEUR(debtToken).burn(from, debtAmount);

// Burn collateral tokens from user
IColToken(colToken).burn(from, collateralAmount);

// Transfer collateral to liquidator
IVault(vault).unlockCollateral(liquidator, collateralAmount);
```

## Liquidation Parameters

### Per-Asset Configuration

Each collateral asset has specific liquidation parameters:

#### ETH Liquidation Parameters

```solidity
liquidationThreshold: 8500,     // 85% - liquidation trigger
liquidationBonus: 10500,        // 105% - 5% discount to liquidators
liquidationProtocolFee: 1000,   // 10% of bonus goes to protocol
```

#### LINK Liquidation Parameters

```solidity
liquidationThreshold: 7500,     // 75% - liquidation trigger
liquidationBonus: 11000,        // 110% - 10% discount to liquidators
liquidationProtocolFee: 1000,   // 10% of bonus goes to protocol
```

### Liquidation Bonus Distribution

When liquidation occurs, the bonus is distributed as follows:

```
Total Liquidation Bonus = Debt Repaid × (Liquidation Bonus - 100%)
Liquidator Receives = Total Bonus × (100% - Protocol Fee%)
Protocol Receives = Total Bonus × Protocol Fee%
```

**Example:**

- Debt repaid: $1,000
- ETH liquidation bonus: 5%
- Protocol fee: 10% of bonus
- Total bonus: $1,000 × 0.05 = $50
- Liquidator gets: $50 × 0.90 = $45 extra value
- Protocol gets: $50 × 0.10 = $5

## Liquidation Limits

### 50% Maximum Rule

To prevent excessive liquidation, only 50% of a user's debt can be liquidated per transaction:

```solidity
uint256 maxLiquidatable = userDebtBalance / 2;
if (debtAmount > maxLiquidatable) {
    debtAmount = maxLiquidatable;
}
```

**Benefits:**

- Prevents complete liquidation in one transaction
- Gives users opportunity to improve their position
- Reduces liquidation trauma
- Ensures more predictable liquidation outcomes

### Collateral Availability Check

The system checks if sufficient collateral is available:

```solidity
uint256 userCollateralBalance = IERC20(colToken).balanceOf(from);
if (collateralAmountToSeize > userCollateralBalance) {
    // Adjust liquidation amount based on available collateral
    collateralAmountToSeize = userCollateralBalance;
    // Recalculate debt amount accordingly
    debtAmount = calculateMaxDebtFromCollateral(collateralAmountToSeize);
}
```

## Liquidation Economics

### Liquidator Incentives

Liquidators are motivated by several factors:

1. **Immediate Profit**: Liquidation bonus provides instant arbitrage
2. **Risk-Free**: No market risk if executed quickly
3. **Scalable**: Can liquidate multiple positions
4. **MEV Opportunities**: Front-running and atomic arbitrage

### Liquidator Strategies

#### 1. Monitoring Strategy

```
Monitor → Detect Liquidatable Position → Execute Liquidation → Profit
```

#### 2. Atomic Arbitrage Strategy

```
Flash Loan → Liquidate Position → Sell Collateral → Repay Loan → Keep Profit
```

#### 3. Portfolio Strategy

```
Hold Debt Tokens → Liquidate with Existing Tokens → Acquire Discounted Collateral
```

## Liquidation Examples

### Example 1: ETH Liquidation

**Setup:**

- User has 5 ETH collateral worth $12,000 (ETH = $2,400)
- User has $10,000 EURC debt
- Health factor drops to 0.95

**Liquidation:**

- Liquidator repays $5,000 EURC (50% max)
- ETH liquidation bonus: 5%
- Collateral to seize: ($5,000 × 1.05) / $2,400 = 2.1875 ETH
- Liquidator profit: 2.1875 ETH - ($5,000 / $2,400) = 0.1042 ETH ≈ $250

**Result:**

- User debt reduced: $10,000 → $5,000
- User collateral reduced: 5 ETH → 2.8125 ETH
- New health factor: (2.8125 × $2,400 × 0.85) / $5,000 = 1.148 (Safe)

### Example 2: LINK Liquidation

**Setup:**

- User has 1,000 LINK collateral worth $15,000 (LINK = $15)
- User has $10,000 EURC debt
- Health factor drops to 0.90

**Liquidation:**

- Liquidator repays $5,000 EURC (50% max)
- LINK liquidation bonus: 10%
- Collateral to seize: ($5,000 × 1.10) / $15 = 366.67 LINK
- Liquidator profit: 366.67 LINK - ($5,000 / $15) = 33.33 LINK ≈ $500

**Result:**

- User debt reduced: $10,000 → $5,000
- User collateral reduced: 1,000 LINK → 633.33 LINK
- New health factor: (633.33 × $15 × 0.75) / $5,000 = 1.425 (Safe)

## Partial vs Full Liquidation

### Partial Liquidation (Standard)

- Maximum 50% of debt per transaction
- Preserves user position
- Allows recovery opportunity
- Multiple liquidations may be needed

### Close Factor Strategy

For severely undercollateralized positions:

- Multiple liquidators can participate
- Sequential liquidations improve health factor
- Market efficiency through competition

## Gas Optimization

### Efficient Liquidation

The liquidation process is optimized for gas efficiency:

```solidity
// Single transaction execution
function liquidate(...) external {
    // Batch validations
    // Optimized calculations
    // Minimal storage writes
    // Efficient token transfers
}
```

### Batch Liquidations

For multiple positions:

```solidity
// Future enhancement: batch multiple liquidations
function batchLiquidate(
    LiquidationCall[] calldata calls
) external {
    for (uint i = 0; i < calls.length; i++) {
        _executeLiquidation(calls[i]);
    }
}
```

## MEV and Front-Running

### MEV Opportunities

- Liquidation creates immediate arbitrage opportunities
- Atomic liquidation + DEX selling strategies
- Flash loan integration for capital efficiency

### Front-Running Protection

- Time-weighted health factor checks
- Oracle update delays
- Liquidation cooldown periods (if needed)

## Error Handling

### Common Liquidation Errors

```solidity
error Pool_HealthFactorNotLiquidatable();
error Pool_AssetNotAllowed(address asset);
error Pool_InvalidAmount();
error Pool_CollateralPaused();
error Pool_DebtPaused();
error Pool_InsufficientCollateral();
```

### Liquidation Failure Cases

1. **Health factor ≥ 1.0**: Position not liquidatable
2. **Asset paused**: Liquidation temporarily disabled
3. **Insufficient collateral**: User doesn't have enough collateral
4. **Oracle failure**: Price data unavailable
5. **Slippage**: Price moved during transaction

## Monitoring and Analytics

### Health Factor Monitoring

Liquidators typically monitor:

- Real-time health factors across all positions
- Price feed updates from oracles
- Gas price optimization
- Profitable liquidation opportunities

### Liquidation Dashboard Metrics

- Total liquidations per day
- Average liquidation size
- Liquidation bonus distribution
- Health factor distribution
- Time to liquidation after threshold breach

The liquidation system ensures ZEUR protocol safety while providing fair incentives for liquidators to maintain system health efficiently.
