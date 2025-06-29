# Pool Contract Documentation

## Overview

The **Pool** contract is the core lending protocol contract that manages all lending and borrowing operations in the Zeur protocol. It handles two types of assets: **collateral assets** (ETH, LINK) and **debt assets** (EUR-based stablecoins). The contract implements a comprehensive lending system with liquid staking token (LST) integration, health factor-based risk management, and automated liquidation mechanisms.

## Architecture

### Contract Inheritance

- `Initializable` - OpenZeppelin upgradeable initialization
- `AccessManagedUpgradeable` - Role-based access control
- `ReentrancyGuardUpgradeable` - Protection against reentrancy attacks
- `UUPSUpgradeable` - Upgradeable proxy pattern support
- `IPool` - Interface implementation

### Storage Structure

The contract uses ERC-7201 namespaced storage to avoid storage collisions:

```solidity
struct PoolStorage {
    IChainlinkOracleManager _oracleManager;
    EnumerableSet.AddressSet _collateralAssetList;
    EnumerableSet.AddressSet _debtAssetList;
    mapping(address => CollateralConfiguration) _collateralConfigurations;
    mapping(address => DebtConfiguration) _debtConfigurations;
}
```

### Key Constants

- `ETH_ADDRESS`: `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` - Represents native ETH
- `HEALTH_FACTOR_BASE`: Minimum health factor threshold (typically 1e18)

## Core Functionality

### 1. Supply Operations

#### `supply(address asset, uint256 amount, address from)`

Allows users to supply assets to the protocol as collateral or for earning yield.

**For Collateral Assets (ETH/LINK):**

- Transfers asset to the token vault
- Triggers staking through vault (for LST generation)
- Mints corresponding colToken (colETH/colLINK) to user
- For ETH: Requires exact `msg.value` matching amount

**For Debt Assets (EUR):**

- Transfers EUR to the protocol
- Deposits into ERC4626 colEUR vault
- Mints colEUR shares to user

**Validations:**

- Asset must be initialized in the protocol
- Amount must be non-zero
- Asset must not be paused
- Asset must not be frozen (for supply operations)
- Must not exceed supply cap

### 2. Withdraw Operations

#### `withdraw(address asset, uint256 amount, address to)`

Allows users to withdraw their supplied assets.

**For Collateral Assets:**

- Burns user's colToken
- Unlocks collateral from vault (unstaking if needed)
- Transfers asset to specified address

**For Debt Assets:**

- Withdraws from colEUR vault
- Transfers EUR to specified address

**Health Factor Check:**
After withdrawal, user's health factor must remain ≥ 1.0

### 3. Borrow Operations

#### `borrow(address asset, uint256 amount, address to)`

Allows users to borrow debt assets against their collateral.

**Process:**

- Validates asset is a debt asset
- Checks user's available borrowing capacity
- Mints debt tokens (debtEUR) to borrower
- Transfers actual asset from colEUR to recipient

**Key Validations:**

- User must have sufficient available borrow value
- Must not exceed borrow cap
- Asset must not be paused or frozen

### 4. Repay Operations

#### `repay(address asset, uint256 amount, address from)`

Allows repayment of borrowed debt.

**Process:**

- Transfers repayment asset to colEUR
- Burns corresponding debt tokens from user
- Reduces user's debt balance

### 5. Liquidation System

#### `liquidate(address collateralAsset, address debtAsset, uint256 debtAmount, address from)`

Enables liquidation of undercollateralized positions.

**Liquidation Conditions:**

- User's health factor < 1.0
- Assets must not be paused
- Liquidation possible even when assets are frozen

**Liquidation Process:**

1. **Health Factor Check**: Validates user is liquidatable
2. **Price Calculation**: Gets asset prices from oracle
3. **Bonus Calculation**: Applies liquidation bonus to incentivize liquidators
4. **Collateral Seizure**: Calculates collateral amount to seize
5. **Debt Repayment**: Liquidator pays debt, burns debt tokens
6. **Collateral Transfer**: Liquidator receives collateral at discount

**Key Features:**

- Partial liquidations supported
- Automatic adjustment if user has insufficient collateral
- Liquidation bonus provides incentive to liquidators
- Protocol fee on liquidation bonus

## Administrative Functions

### Asset Initialization

#### `initCollateralAsset(address collateralAsset, CollateralConfiguration memory collateralConfiguration)`

Adds a new collateral asset to the protocol.

**Configuration Parameters:**

- `supplyCap`: Maximum total supply allowed
- `borrowCap`: Maximum borrowing against this collateral
- `colToken`: Address of corresponding collateral token
- `tokenVault`: Address of asset vault for staking
- `ltv`: Loan-to-value ratio (basis points)
- `liquidationThreshold`: Liquidation trigger threshold
- `liquidationBonus`: Liquidator incentive bonus
- `liquidationProtocolFee`: Protocol's share of liquidation
- `reserveFactor`: Protocol reserve percentage
- `isFrozen`: Emergency freeze status
- `isPaused`: Emergency pause status

#### `initDebtAsset(address debtAsset, DebtConfiguration memory debtConfiguration)`

Adds a new debt asset to the protocol.

**Configuration Parameters:**

- `supplyCap`: Maximum supply capacity
- `borrowCap`: Maximum borrowing capacity
- `colToken`: Address of colEUR token
- `debtToken`: Address of corresponding debt token
- `reserveFactor`: Protocol reserve percentage
- `isFrozen`: Emergency freeze status
- `isPaused`: Emergency pause status

### Configuration Updates

#### `setCollateralConfiguration()` / `setDebtConfiguration()`

Updates existing asset configurations. Only accessible by authorized roles.

## Query Functions

### Asset Information

#### `getCollateralAssetList()` / `getDebtAssetList()`

Returns arrays of all registered collateral/debt assets.

#### `getCollateralAssetConfiguration()` / `getDebtAssetConfiguration()`

Returns complete configuration for specific assets.

#### `getAssetType(address asset)`

Returns asset type: `NoneAsset`, `Collateral`, or `Debt`.

### User Account Data

#### `getUserAccountData(address user)`

Returns comprehensive user account information:

```solidity
struct UserAccountData {
    uint256 totalCollateralValue;     // Total collateral value in USD
    uint256 totalDebtValue;           // Total debt value in USD
    uint256 availableBorrowsValue;    // Available borrowing capacity
    uint256 currentLiquidationThreshold; // Weighted avg liquidation threshold
    uint256 ltv;                      // Current loan-to-value ratio
    uint256 healthFactor;             // Health factor (>1 = safe, <1 = liquidatable)
}
```

## Risk Management

### Health Factor Calculation

Health Factor = (Total Collateral Value × Liquidation Threshold) / (Total Debt Value × 10000)

- **> 1.0**: Position is safe
- **< 1.0**: Position can be liquidated
- **No debt**: Health factor = max uint256 (infinite)

### Risk Parameters

#### Loan-to-Value (LTV)

- Maximum borrowing power against collateral
- Example: 75% LTV means $75 borrowing per $100 collateral

#### Liquidation Threshold

- Point at which liquidation becomes possible
- Always higher than LTV (e.g., 80% vs 75% LTV)

#### Liquidation Bonus

- Discount liquidators receive on seized collateral
- Incentivizes timely liquidation
- Example: 5% bonus (10500 basis points)

### Emergency Controls

#### Freeze vs Pause

- **Frozen**: Users can withdraw/repay/liquidate but not supply/borrow
- **Paused**: No operations allowed (emergency stop)

## Integration Points

### Oracle Integration

- Uses Chainlink Oracle Manager for price feeds
- All calculations in USD with 8 decimal precision
- Supports multiple asset price sources

### Vault Integration

- Collateral assets stored in specialized vaults
- Automatic staking to liquid staking protocols
- Yield generation through LST strategies

### Token Integration

- **Collateral Tokens**: colETH, colLINK (represent staked positions)
- **Debt Tokens**: debtEUR (represent borrowing positions)
- **Supply Tokens**: colEUR (ERC4626 vault shares)

## Security Features

### Access Control

- Role-based permissions using AccessManager
- Critical functions restricted to authorized roles
- Upgrade authority controlled by governance

### Reentrancy Protection

- All external functions protected with `nonReentrant`
- Safe transfer patterns using OpenZeppelin SafeERC20

### Validation Layers

- Input validation for all parameters
- Asset existence checks
- Configuration validation
- Health factor enforcement

### Upgrade Safety

- UUPS upgradeable pattern
- Storage collision protection via ERC-7201
- Controlled upgrade authorization

## Economic Model

### Interest Rate Model

- Dynamic rates based on utilization
- Reserve factor accumulation
- Yield distribution to suppliers

### Liquidation Economics

- Liquidation bonus attracts liquidators
- Protocol fee on liquidations
- Partial liquidation support prevents excessive liquidation

### Yield Generation

- LST staking rewards for collateral holders
- Supply yield for debt asset providers
- Protocol reserve accumulation

## Error Handling

The contract defines comprehensive error types:

- `Pool_AssetNotAllowed`: Asset not initialized
- `Pool_InvalidAmount`: Zero or invalid amount
- `Pool_InsufficientHealthFactor`: Health factor too low
- `Pool_SupplyCapExceeded`: Asset supply limit reached
- `Pool_BorrowCapExceeded`: Asset borrow limit reached
- `Pool_CollateralFrozen/Paused`: Emergency state active
- `Pool_HealthFactorNotLiquidatable`: User not eligible for liquidation

## Events

All major operations emit events for off-chain monitoring:

- `Supply`, `Withdraw`, `Borrow`, `Repay`, `Liquidate`
- `InitCollateralAsset`, `InitDebtAsset`
- `SetCollateralConfiguration`, `SetDebtConfiguration`

## Best Practices

### For Users

1. Monitor health factor regularly
2. Maintain adequate collateralization
3. Understand liquidation risks
4. Consider market volatility in position sizing

### For Integrators

1. Always check asset type before operations
2. Implement proper error handling
3. Monitor events for state changes
4. Respect emergency controls (freeze/pause)

### For Administrators

1. Set conservative risk parameters initially
2. Monitor utilization rates and caps
3. Regular risk parameter reviews
4. Emergency response procedures

## Technical Implementation Notes

### Gas Optimization

- Batch operations where possible
- Efficient storage layout with packing
- Minimal external calls per operation

### Precision Handling

- 18-decimal precision for calculations
- Proper decimal scaling for different assets
- Safe math operations throughout

### State Management

- Atomic operations for consistency
- Proper state updates before external calls
- Event emission for all state changes

This documentation provides a comprehensive understanding of the Pool contract's functionality, security measures, and integration points. The contract serves as the foundation of the Zeur lending protocol, enabling secure and efficient lending and borrowing operations with integrated liquid staking capabilities.
