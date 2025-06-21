# ZEUR Borrowing and Lending

## Overview

The ZEUR protocol enables users to borrow EUR-denominated stablecoins against crypto collateral while also allowing EUR stablecoin holders to earn lending interest. This creates a two-sided marketplace where borrowers access EUR liquidity and lenders earn yield on their EUR deposits.

## Borrowing Mechanics

### Supported Debt Assets

ZEUR currently supports borrowing against these EUR stablecoins:

#### EURC (Circle EUR)

- **Issuer**: Circle
- **Decimals**: 6
- **Backing**: 1:1 EUR reserves
- **Liquidity**: High secondary market liquidity
- **Regulatory**: EU MiCA compliant

### Borrowing Process

#### 1. Collateral Supply

Users must first supply collateral before borrowing:

```solidity
// Supply 10 ETH as collateral
pool.supply{value: 10 ether}(ETH_ADDRESS, 10 ether, user);
```

#### 2. Calculate Borrowing Capacity

```solidity
function getUserAccountData(address user) external view returns (UserAccountData memory) {
    // Calculate total collateral value
    uint256 totalCollateralValue = calculateUserCollateralValue(user);

    // Calculate weighted LTV
    uint256 weightedLTV = calculateWeightedLTV(user);

    // Available borrows = collateral value × weighted LTV - current debt
    uint256 availableBorrows = (totalCollateralValue * weightedLTV / 10000) - currentDebt;

    return UserAccountData({
        totalCollateralValue: totalCollateralValue,
        availableBorrowsValue: availableBorrows,
        // ... other fields
    });
}
```

#### 3. Execute Borrow

```solidity
// Borrow 5,000 EURC against ETH collateral
pool.borrow(EURC_ADDRESS, 5000e6, user);
```

**Borrow Process:**

1. **Validation**: Check borrowing capacity and asset status
2. **Health Factor**: Ensure health factor remains > 1.0
3. **Debt Tracking**: Mint debtEUR tokens to user
4. **Asset Transfer**: Transfer EURC from ColEUR vault to user

### Borrowing Limits

#### Individual Limits

- **Maximum LTV**: Asset-specific (80% ETH, 70% LINK)
- **Health Factor**: Must remain above 1.0
- **Borrow Cap**: Per-asset protocol limits

#### Protocol Limits

```solidity
struct DebtConfiguration {
    uint256 borrowCap;  // Maximum total borrowing for this asset
    // ... other fields
}
```

## Lending Mechanics (EUR Supply)

### EUR Stablecoin Lending

Users can supply EUR stablecoins to earn lending interest:

#### Supply Process

```solidity
// Supply 50,000 EURC to earn interest
pool.supply(EURC_ADDRESS, 50000e6, user);
```

**Supply Process:**

1. **Asset Transfer**: EURC transferred from user to protocol
2. **Vault Deposit**: EURC deposited into ColEUR ERC4626 vault
3. **Share Minting**: User receives ColEUR shares representing deposit
4. **Interest Accrual**: User earns interest as borrowers repay loans

### ColEUR Vault Integration

ColEUR is an ERC4626 vault that manages EUR stablecoin deposits:

```solidity
contract ColEUR is ERC4626Upgradeable {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        // Calculate shares based on current exchange rate
        uint256 shares = convertToShares(assets);

        // Transfer EURC to vault
        asset().safeTransferFrom(msg.sender, address(this), assets);

        // Mint shares to user
        _mint(receiver, shares);
    }
}
```

## Interest Rate Model

### Utilization-Based Interest

Interest rates are determined by utilization ratio:

```
Utilization Rate = Total Borrowed / Total Supplied
```

### Interest Rate Calculation

```solidity
function calculateInterestRate(uint256 totalBorrowed, uint256 totalSupplied) internal pure returns (uint256) {
    if (totalSupplied == 0) return 0;

    uint256 utilizationRate = (totalBorrowed * 1e18) / totalSupplied;

    // Base rate + utilization rate × slope
    uint256 baseRate = 2e16; // 2% base APR
    uint256 slope = 10e16;   // 10% slope
    uint256 optimalUtilization = 80e16; // 80% optimal

    if (utilizationRate <= optimalUtilization) {
        return baseRate + (utilizationRate * slope) / 1e18;
    } else {
        // Steep slope after optimal utilization
        uint256 excessUtilization = utilizationRate - optimalUtilization;
        uint256 steepSlope = 50e16; // 50% steep slope
        return baseRate + (optimalUtilization * slope) / 1e18 + (excessUtilization * steepSlope) / 1e18;
    }
}
```

### Example Interest Rates

| Utilization | Borrow APR | Supply APR |
| ----------- | ---------- | ---------- |
| 0%          | 2%         | 0%         |
| 40%         | 6%         | 2.2%       |
| 80%         | 10%        | 7.2%       |
| 90%         | 15%        | 12.2%      |
| 95%         | 17.5%      | 15.7%      |

## Repayment Process

### Full Repayment

```solidity
// Repay all EURC debt
uint256 debtBalance = IERC20(debtEUR).balanceOf(user);
pool.repay(EURC_ADDRESS, debtBalance, user);
```

### Partial Repayment

```solidity
// Repay 2,000 EURC of debt
pool.repay(EURC_ADDRESS, 2000e6, user);
```

**Repayment Process:**

1. **Asset Transfer**: EURC transferred from user to ColEUR vault
2. **Debt Burning**: Corresponding debtEUR tokens burned
3. **Capacity Update**: User's borrowing capacity increases
4. **Health Factor**: Health factor improves

## EUR Stablecoin Withdrawal

### Withdrawal Process

```solidity
// Withdraw 10,000 EURC from lending
pool.withdraw(EURC_ADDRESS, 10000e6, user);
```

**Withdrawal Process:**

1. **Share Burning**: Burn user's ColEUR shares
2. **Asset Transfer**: Transfer EURC from vault to user
3. **Interest Included**: User receives principal + accrued interest

### Withdrawal Limits

- **Available Liquidity**: Limited by vault liquidity
- **Utilization Cap**: Cannot withdraw if utilization too high

## Multi-Asset Portfolio Management

### Cross-Collateral Borrowing

Users can deposit multiple collateral types:

```solidity
// Supply both ETH and LINK as collateral
pool.supply{value: 5 ether}(ETH_ADDRESS, 5 ether, user);
pool.supply(LINK_ADDRESS, 1000e18, user);

// Borrow against combined collateral
pool.borrow(EURC_ADDRESS, 8000e6, user);
```

### Weighted Risk Calculations

For multi-asset portfolios:

```solidity
function calculateWeightedLTV(address user) internal view returns (uint256) {
    uint256 totalCollateralValue = 0;
    uint256 weightedLTVSum = 0;

    address[] memory assets = getCollateralAssets();
    for (uint i = 0; i < assets.length; i++) {
        uint256 userBalance = getUserCollateralBalance(user, assets[i]);
        if (userBalance > 0) {
            uint256 assetValue = calculateAssetValue(assets[i], userBalance);
            uint256 assetLTV = getAssetConfiguration(assets[i]).ltv;

            totalCollateralValue += assetValue;
            weightedLTVSum += assetValue * assetLTV;
        }
    }

    return totalCollateralValue > 0 ? weightedLTVSum / totalCollateralValue : 0;
}
```

## Borrowing Strategies

### Strategy 1: Conservative Borrowing

- **Collateral**: ETH (stable, high LTV)
- **Borrowed Amount**: 50% of maximum capacity
- **Purpose**: EUR exposure with safety margin

### Strategy 2: Leveraged Staking

- **Collateral**: Multiple LST protocols
- **Borrowed Amount**: 70-80% of maximum capacity
- **Purpose**: Maximize staking yield while accessing EUR

### Strategy 3: Arbitrage Opportunities

- **Collateral**: Various assets
- **Borrowed Amount**: Varies based on opportunities
- **Purpose**: EUR/USD arbitrage trading

## Risk Management for Borrowers

### Health Factor Monitoring

```solidity
// Check health factor before large operations
UserAccountData memory userData = pool.getUserAccountData(user);
require(userData.healthFactor >= 1.1e18, "Position too risky");
```

### Liquidation Prevention

1. **Monitor Health Factor**: Keep above 1.2 for safety
2. **Diversify Collateral**: Use multiple asset types
3. **Conservative LTV**: Borrow less than maximum
4. **Active Management**: Repay during market stress

## Interest Accrual and Compounding

### Continuous Compounding

Interest accrues continuously using compound interest:

```solidity
function calculateCompoundInterest(
    uint256 principal,
    uint256 rate,
    uint256 time
) internal pure returns (uint256) {
    // A = P * e^(rt)
    // Approximated using: A = P * (1 + r/n)^(nt)
    // Where n = blocks per year for high precision
}
```

### Interest Distribution

For ColEUR vault holders:

```
Supply APR = Borrow APR × Utilization Rate × (1 - Reserve Factor)
```

**Example:**

- Borrow APR: 10%
- Utilization: 80%
- Reserve Factor: 10%
- Supply APR: 10% × 80% × 90% = 7.2%

## Flash Loans (Future Feature)

### Flash Loan Integration

```solidity
function flashLoan(
    address asset,
    uint256 amount,
    bytes calldata params
) external {
    // Lend asset with 0.1% fee
    // Borrower must repay within same transaction
}
```

### Use Cases

- **Arbitrage**: EUR/USD price differences
- **Liquidation**: Flash loan to liquidate positions
- **Refinancing**: Move positions between protocols

## Gas Optimization

### Batch Operations

```solidity
struct BatchOperation {
    address asset;
    uint256 amount;
    uint8 operation; // 0=supply, 1=withdraw, 2=borrow, 3=repay
}

function batchExecute(BatchOperation[] calldata operations) external {
    for (uint i = 0; i < operations.length; i++) {
        executeBatchOperation(operations[i]);
    }
}
```

### Efficient Interest Calculations

- Pre-computed interest rate curves
- Batch interest accrual updates
- Optimized storage patterns

## Monitoring and Analytics

### Key Metrics

- **Total Value Locked (TVL)**: Sum of all collateral
- **Total Borrowed**: Sum of all outstanding debt
- **Utilization Rate**: Borrowed / Supplied ratio
- **Average Health Factor**: Portfolio risk metric
- **Interest Earned**: Total interest paid to lenders

### User Dashboard Metrics

- Current borrowing capacity
- Health factor with price impact simulation
- Interest accrued on supplies
- Liquidation price levels

The borrowing and lending system provides efficient EUR stablecoin access while generating sustainable yield for EUR suppliers through a robust interest rate model.
