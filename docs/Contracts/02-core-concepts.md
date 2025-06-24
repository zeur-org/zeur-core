# ZEUR Core Concepts

## Key Terminology

### Assets

- **Collateral Asset**: Crypto assets that can be deposited as collateral (ETH, LINK)
- **Debt Asset**: Stablecoins that can be borrowed (EURC, EURI)
- **Underlying Asset**: The original asset before tokenization
- **Tokenized Asset**: Wrapped representation of deposits/debts

### Tokens

- **ColToken**: Represents collateral deposits (colETH, colLINK)
- **DebtToken**: Represents borrowed amounts (debtEUR)
- **ColEUR**: ERC4626 vault token for EUR stablecoin deposits

### Financial Metrics

- **LTV (Loan-to-Value)**: Maximum borrowing power as percentage of collateral value
- **Liquidation Threshold**: Health factor threshold below which liquidation occurs
- **Health Factor**: Measure of position safety (collateral value × threshold / debt value)
- **Liquidation Bonus**: Discount liquidators receive on seized collateral

## Core Mechanics

### 1. Collateral Supply

When users supply collateral assets:

```solidity
// User supplies ETH/LINK
Pool.supply(asset, amount, user)
```

**Process:**

1. User transfers asset to the protocol
2. Asset is forwarded to the appropriate vault
3. Vault stakes the asset across LST protocols
4. User receives colToken representing their deposit
5. User can now borrow against this collateral

**For ETH:**

- Asset goes to VaultETH
- Automatically distributed across Lido, RocketPool, EtherFi, Morpho
- User receives colETH tokens

**For LINK:**

- Asset goes to VaultLINK
- Automatically stakes via StakeLink
- User receives colLINK tokens

### 2. EUR Stablecoin Supply

Users can also supply EUR stablecoins to earn lending interest:

```solidity
// User supplies EURC to earn interest
Pool.supply(EURC, amount, user)
```

**Process:**

1. User transfers EURC to the protocol
2. EURC is deposited into ColEUR vault (ERC4626)
3. User receives ColEUR shares representing their deposit
4. User earns interest from borrowers

### 3. Borrowing

Users borrow EUR stablecoins against their collateral:

```solidity
// User borrows EURC against collateral
Pool.borrow(EURC, amount, user)
```

**Process:**

1. Protocol checks user's available borrowing capacity
2. Mints debtEUR tokens to track the debt
3. Transfers EURC from ColEUR vault to user
4. User's health factor is updated

### 4. Repayment

Users repay their loans to unlock collateral:

```solidity
// User repays EURC loan
Pool.repay(EURC, amount, user)
```

**Process:**

1. User transfers EURC to ColEUR vault
2. Protocol burns corresponding debtEUR tokens
3. User's debt balance decreases
4. Borrowing capacity increases

### 5. Withdrawal

Users can withdraw their collateral (subject to utilization):

```solidity
// User withdraws ETH collateral
Pool.withdraw(ETH, amount, user)
```

**Process:**

1. Protocol checks user's health factor remains > 1
2. Burns user's colToken
3. Unstakes assets from LST protocols via vault
4. Transfers unstaked assets to user

## Mathematical Formulas

### Health Factor Calculation

```
Health Factor = (Collateral Value × Liquidation Threshold) / Debt Value
```

Where:

- **Collateral Value**: Sum of all collateral in USD
- **Liquidation Threshold**: Weighted average threshold across all collateral
- **Debt Value**: Sum of all debt in USD

**Example:**

- User has $10,000 ETH collateral (85% liquidation threshold)
- User has $7,000 EURC debt
- Health Factor = ($10,000 × 0.85) / $7,000 = 1.21

### Available Borrowing Capacity

```
Available Borrow = (Collateral Value × LTV) - Current Debt
```

**Example:**

- User has $10,000 ETH collateral (80% LTV)
- User has $5,000 current debt
- Available Borrow = ($10,000 × 0.80) - $5,000 = $3,000

### Liquidation Calculation

```
Max Liquidation = User Debt × 50%
Collateral Seized = (Debt Repaid × Debt Price × Liquidation Bonus) / Collateral Price
```

**Example:**

- User has $8,000 EURC debt (Health Factor = 0.9)
- Liquidator repays $4,000 EURC (50% max)
- ETH liquidation bonus = 5%
- Collateral Seized = ($4,000 × 1.05) / ETH_Price

### Weighted Average Calculations

For users with multiple collateral types:

```
Weighted LTV = Σ(Collateral_Value_i × LTV_i) / Total_Collateral_Value
Weighted Liquidation Threshold = Σ(Collateral_Value_i × Threshold_i) / Total_Collateral_Value
```

## Asset Configurations

### Collateral Configuration

Each collateral asset has the following parameters:

```solidity
struct CollateralConfiguration {
    uint256 supplyCap;              // Maximum total supply
    uint256 borrowCap;              // Maximum borrowing against this collateral
    address colToken;               // Associated colToken contract
    address tokenVault;             // Associated vault contract
    uint16 ltv;                     // Loan-to-value ratio (bps)
    uint16 liquidationThreshold;    // Liquidation threshold (bps)
    uint16 liquidationBonus;        // Liquidation bonus (bps)
    uint16 liquidationProtocolFee;  // Protocol fee on liquidations (bps)
    uint16 reserveFactor;           // Reserve factor for protocol (bps)
    bool isFrozen;                  // Can't supply/borrow, can withdraw/repay
    bool isPaused;                  // All operations paused
}
```

**Example ETH Configuration:**

- LTV: 80% (8000 bps)
- Liquidation Threshold: 85% (8500 bps)
- Liquidation Bonus: 5% (10500 bps, meaning 105%)
- Reserve Factor: 10% (1000 bps)

### Debt Configuration

Each debt asset has the following parameters:

```solidity
struct DebtConfiguration {
    uint256 supplyCap;              // Maximum EUR that can be supplied
    uint256 borrowCap;              // Maximum EUR that can be borrowed
    address colToken;               // Associated ColEUR vault
    address debtToken;              // Associated debtEUR contract
    uint16 reserveFactor;           // Reserve factor for protocol (bps)
    bool isFrozen;                  // Can't supply/borrow, can withdraw/repay
    bool isPaused;                  // All operations paused
}
```

## State Management

### User Account Data

The protocol tracks comprehensive user data:

```solidity
struct UserAccountData {
    uint256 totalCollateralValue;          // Total collateral in USD
    uint256 totalDebtValue;                // Total debt in USD
    uint256 availableBorrowsValue;         // Remaining borrow capacity
    uint256 currentLiquidationThreshold;   // Weighted average threshold
    uint256 ltv;                           // Current loan-to-value ratio
    uint256 healthFactor;                  // Position health (18 decimals)
}
```

### Asset States

Assets can be in different states:

1. **Active**: Normal operations allowed
2. **Frozen**: Can withdraw/repay but not supply/borrow
3. **Paused**: No operations allowed (emergency only)

## Price Oracle Integration

### Chainlink Integration

The protocol uses Chainlink oracles for all price data:

```solidity
interface IChainlinkOracleManager {
    function getAssetPrice(address asset) external view returns (uint256);
}
```

**Price Format:**

- All prices returned in USD with 8 decimals (Chainlink standard)
- ETH/USD: e.g., 300000000000 (=$3,000.00)
- EURC/USD: e.g., 108000000 (=$1.08)

### Price Calculations

When calculating values, the protocol accounts for token decimals:

```solidity
// Convert token amount to USD value
uint256 valueInUSD = (amount * priceInUSD) / 10^tokenDecimals
```

**Example:**

- 2 ETH (18 decimals) at $3,000
- Value = (2 × 10^18 × 3000 × 10^8) / 10^18 = $6,000 × 10^8

## Security Considerations

### Reentrancy Protection

- All external functions use `nonReentrant` modifier
- State changes before external calls

### Access Control

- Role-based permissions for administrative functions
- Multi-signature requirements for critical operations

### Oracle Security

- Chainlink price feeds for reliable data
- Circuit breakers for extreme price movements
- Multiple oracle sources where possible

### Liquidation Safety

- Maximum 50% liquidation per transaction
- Health factor checks prevent over-liquidation
- Liquidation bonuses incentivize quick liquidations

## Constants and Limits

### System Constants

```solidity
uint256 constant HEALTH_FACTOR_BASE = 1e18;    // Health factor of 1.0
uint256 constant BPS_BASE = 10000;             // Basis points base (100%)
uint256 constant LIQUIDATION_MAX_PERCENT = 50; // Max liquidation percentage
```

### Decimal Handling

Different assets have different decimals:

- **ETH**: 18 decimals
- **LINK**: 18 decimals
- **EURC**: 6 decimals
- **Prices**: 8 decimals (Chainlink standard)
- **Health Factor**: 18 decimals

All calculations account for these differences to ensure precision.

## Gas Optimization

### Batch Operations

- Multiple LST protocols called in single transaction
- Efficient storage packing in structs
- Minimal external calls

### Storage Efficiency

- Packed structs to minimize storage slots
- EnumerableSet for asset lists
- Upgradeable storage patterns

This foundation enables all higher-level protocol features including lending, borrowing, staking integration, and liquidations.
