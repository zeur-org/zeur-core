# Tokenization System

## Overview

The ZEUR protocol uses a sophisticated tokenization system to represent user positions and enable composability. All user deposits and debts are tokenized into ERC20-compatible tokens that can be tracked, transferred (where applicable), and integrated with other DeFi protocols.

## Token Types

### 1. ColTokens (Collateral Tokens)

ColTokens represent user deposits of collateral assets. They are minted 1:1 with the underlying collateral and serve as proof of deposit.

#### ColETH (Collateral ETH)

```solidity
contract ColToken is ERC20Upgradeable, AccessManagedUpgradeable, UUPSUpgradeable
```

**Characteristics:**

- **Minting**: 1:1 with deposited ETH
- **Transferable**: Yes (freely transferable)
- **Composable**: Can be used in other DeFi protocols
- **Yield-bearing**: Earns staking rewards automatically

**Example:**

- User deposits 5 ETH
- Receives 5 colETH tokens
- ETH automatically stakes across LST protocols
- User earns staking rewards while holding colETH

#### ColLINK (Collateral LINK)

```solidity
contract ColToken is ERC20Upgradeable, AccessManagedUpgradeable, UUPSUpgradeable
```

**Characteristics:**

- **Minting**: 1:1 with deposited LINK
- **Transferable**: Yes (freely transferable)
- **Composable**: Can be used in other DeFi protocols
- **Yield-bearing**: Earns LINK staking rewards

**Functions:**

```solidity
function mint(address account, uint256 value) external restricted;
function burn(address account, uint256 value) external restricted;
function decimals() public pure override returns (uint8) { return 18; }
```

### 2. DebtEUR (Debt Token)

DebtEUR represents borrowed EUR stablecoins. Unlike ColTokens, DebtTokens are non-transferable to prevent debt assignment.

```solidity
contract DebtEUR is ERC20Upgradeable, AccessManagedUpgradeable, UUPSUpgradeable
```

**Characteristics:**

- **Minting**: 1:1 with borrowed EUR amount
- **Non-transferable**: Cannot be transferred between users
- **Account-bound**: Debt stays with the borrower
- **Decimals**: 6 (matches EURC)

**Restricted Functions:**

```solidity
function transfer(address to, uint256 amount) public override returns (bool) {
    revert DebtEUR_OperationNotAllowed();
}

function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
    revert DebtEUR_OperationNotAllowed();
}

function approve(address spender, uint256 amount) public override returns (bool) {
    revert DebtEUR_OperationNotAllowed();
}
```

**Example:**

- User borrows 1,000 EURC
- 1,000 debtEUR tokens are minted to user
- Tokens cannot be transferred to another address
- User must repay to burn debtEUR tokens

### 3. ColEUR (Collateral EUR)

ColEUR is an ERC4626 vault that represents EUR stablecoin deposits. It's used for EUR suppliers who want to earn lending interest.

```solidity
contract ColEUR is ERC4626Upgradeable, ERC20PermitUpgradeable, AccessManagedUpgradeable, UUPSUpgradeable
```

**Characteristics:**

- **Standard**: ERC4626 vault token
- **Underlying**: EURC (or other EUR stablecoins)
- **Shares**: Represent proportional ownership of EUR pool
- **Transferable**: Yes (freely transferable)
- **Interest-bearing**: Earns interest from borrowers

**Key Functions:**

```solidity
function deposit(uint256 assets, address receiver) external returns (uint256 shares);
function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
function mint(uint256 shares, address receiver) external returns (uint256 assets);
function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
function transferTokenTo(address to, uint256 amount) external; // For Pool contract
```

**Example:**

- User deposits 10,000 EURC
- Receives ColEUR shares based on current exchange rate
- Earns interest as borrowers pay back loans
- Can withdraw EURC + accrued interest anytime

## Token Mechanics

### 1. ColToken Mechanics

#### Minting Process

```solidity
function supply(address asset, uint256 amount, address from) external {
    // For ETH/LINK collateral
    if (collateralAssetList.contains(asset)) {
        // Transfer asset to vault
        vault.lockCollateral(from, amount);
        // Mint colToken 1:1
        colToken.mint(from, amount);
    }
}
```

#### Burning Process

```solidity
function withdraw(address asset, uint256 amount, address to) external {
    // Burn colToken from user
    colToken.burn(msg.sender, amount);
    // Unlock collateral from vault
    vault.unlockCollateral(to, amount);
    // Check health factor remains > 1
    require(getUserHealthFactor(msg.sender) >= HEALTH_FACTOR_BASE);
}
```

#### Staking Integration

ColTokens automatically earn staking rewards through the vault system:

```
User Deposit → ColToken Mint → Vault Stakes → LST Rewards → User Benefits
```

### 2. DebtEUR Mechanics

#### Debt Creation

```solidity
function borrow(address asset, uint256 amount, address to) external {
    // Check borrowing capacity
    require(availableBorrowsValue >= debtValue);
    // Mint debtEUR to track debt
    debtToken.mint(msg.sender, amount);
    // Transfer EUR from ColEUR vault
    colEUR.transferTokenTo(to, amount);
}
```

#### Debt Repayment

```solidity
function repay(address asset, uint256 amount, address from) external {
    // Transfer EUR back to ColEUR vault
    assetToken.safeTransferFrom(msg.sender, colEUR, amount);
    // Burn debtEUR tokens
    debtToken.burn(from, amount);
}
```

### 3. ColEUR Vault Mechanics

#### Share Calculation

ColEUR follows ERC4626 standard for share calculations:

```solidity
// Shares to assets
function convertToAssets(uint256 shares) public view returns (uint256) {
    return shares * totalAssets() / totalSupply();
}

// Assets to shares
function convertToShares(uint256 assets) public view returns (uint256) {
    return assets * totalSupply() / totalAssets();
}
```

#### Interest Accrual

Interest is earned when:

1. Borrowers pay interest on loans
2. EUR flows back into the ColEUR vault
3. Exchange rate improves for ColEUR holders

## Access Control

### Restricted Functions

Only the Pool contract can call certain functions:

```solidity
modifier restricted() {
    require(hasRole(MINTER_ROLE, msg.sender), "Unauthorized");
    _;
}
```

**ColToken Restricted:**

- `mint()` - Only Pool can mint
- `burn()` - Only Pool can burn

**DebtEUR Restricted:**

- `mint()` - Only Pool can mint
- `burn()` - Only Pool can burn

**ColEUR Restricted:**

- `deposit()` - Only Pool can deposit
- `withdraw()` - Only Pool can withdraw
- `transferTokenTo()` - Only Pool can transfer underlying

### Role Management

```solidity
// Pool contract has minter role for all tokens
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

// Setup in deployment
accessManager.grantRole(MINTER_ROLE, poolAddress);
```

## Token Interactions

### Supply Collateral Flow

```
1. User → Pool.supply(ETH, 5 ether, user)
2. Pool → VaultETH.lockCollateral(user, 5 ether)
3. VaultETH → Stake across LST protocols
4. Pool → ColETH.mint(user, 5 ether)
5. User receives 5 colETH tokens
```

### Borrow Flow

```
1. User → Pool.borrow(EURC, 3000e6, user)
2. Pool → Check borrowing capacity
3. Pool → DebtEUR.mint(user, 3000e6)
4. Pool → ColEUR.transferTokenTo(user, 3000e6)
5. User receives 3000 EURC, owes 3000 debtEUR
```

### Supply EUR Flow

```
1. User → Pool.supply(EURC, 10000e6, user)
2. Pool → EURC.transferFrom(user, pool, 10000e6)
3. Pool → ColEUR.deposit(10000e6, user)
4. User receives ColEUR shares
```

### Liquidation Flow

```
1. Liquidator → Pool.liquidate(ETH, EURC, 2000e6, liquidatedUser)
2. Pool → EURC.transferFrom(liquidator, colEUR, 2000e6)
3. Pool → DebtEUR.burn(liquidatedUser, 2000e6)
4. Pool → ColETH.burn(liquidatedUser, collateralAmount)
5. Pool → VaultETH.unlockCollateral(liquidator, collateralAmount)
```

## Token Standards Compliance

### ERC20 Compliance

All tokens follow ERC20 standard with customizations:

- **ColTokens**: Full ERC20 with transferability
- **DebtEUR**: ERC20 interface but non-transferable
- **ColEUR**: ERC20 + ERC4626 vault standard

### ERC4626 Compliance

ColEUR fully implements ERC4626 vault standard:

```solidity
interface IERC4626 {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function maxDeposit(address receiver) external view returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256);
    // ... other functions
}
```

## Composability

### ColToken Composability

ColTokens can be used in other DeFi protocols:

- **Lending**: Use colETH as collateral in other protocols
- **DEX Trading**: Trade colETH/ETH pairs
- **Yield Farming**: Provide colETH/ETH liquidity
- **Derivatives**: Create options/futures on colETH

### ColEUR Composability

ColEUR shares can be:

- **Traded**: colEUR/EURC pairs on DEXes
- **Composed**: Used in other yield strategies
- **Collateralized**: Used as collateral elsewhere
- **Automated**: Integrated into yield aggregators

## Decimal Handling

### Token Decimals

```solidity
// ColETH & ColLINK
function decimals() public pure override returns (uint8) {
    return 18;
}

// DebtEUR
function decimals() public pure override returns (uint8) {
    return 6;
}

// ColEUR
function decimals() public view override returns (uint8) {
    return IERC20Metadata(asset()).decimals(); // 6 for EURC
}
```

### Precision Considerations

- All internal calculations use appropriate precision
- Cross-decimal conversions handled carefully
- Rounding errors minimized through proper ordering

## Gas Optimization

### Efficient Minting/Burning

- Batch operations where possible
- Minimal storage writes
- Optimized approval mechanisms

### Vault Efficiency

- ERC4626 standard optimizations
- Minimal external calls
- Efficient share calculations

The tokenization system provides the foundation for all ZEUR protocol operations while maintaining composability and standards compliance.
