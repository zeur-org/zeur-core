# Protocol Overview

## What is ZEUR?

ZEUR is a decentralized lending protocol that enables users to borrow EUR-denominated stablecoins against crypto collateral while paying no interest. Their collateral automatically earns staking rewards on their deposited assets and this yield is distributed to EUR lenders. The protocol combines traditional lending mechanics with liquid staking token (LST) integration to maximize capital efficiency and make EUR stablecoins affordable for everyone.

## Key Features

### 🏦 **Collateralized Lending**

- Supply crypto assets (ETH, LINK) as collateral
- Borrow EUR-denominated stablecoins (EURC, EURI) against collateral
- Overcollateralized lending with configurable loan-to-value (LTV) ratios

### 🚀 **Automatic Staking Rewards**

- Deposited ETH automatically stakes across multiple LST protocols (Lido, RocketPool, EtherFi, Morpho)
- Deposited LINK automatically stakes via StakeLink
- Users earn staking rewards while their assets serve as collateral

### 💱 **EUR-Denominated Borrowing**

- Borrow against EUR-pegged stablecoins
- Diversification away from USD-denominated assets
- Support for multiple EUR stablecoins

### 🛡️ **Liquidation Protection**

- Automatic liquidation system to maintain protocol solvency
- Liquidation bonuses for liquidators
- Health factor monitoring

## Architecture Overview

![image](https://github.com/user-attachments/assets/5b3de75e-ea54-4144-8a56-7665592d021f)

## Core Components

### 1. **Pool Contract**

- Central hub for all lending operations
- Handles supply, withdraw, borrow, repay, and liquidate functions
- Manages collateral and debt configurations
- Tracks user positions and health factors

### 2. **Tokenization System**

- **ColTokens**: Represent collateral deposits (colETH, colLINK)
- **DebtTokens**: Represent borrowed amounts (debtEUR)
- **ColEUR**: ERC4626 vault for EUR stablecoin deposits

### 3. **Vault System**

- **VaultETH**: Manages ETH deposits and LST staking strategies
- **VaultLINK**: Manages LINK deposits and staking
- **Staking Routers**: Interface with various LST protocols

### 4. **Oracle Integration**

- Chainlink price feeds for accurate asset valuations
- Real-time price updates for liquidation calculations
- Multi-asset price support (ETH, LINK, EURC, etc.)

### 5. **Access Management**

- Role-based access control system
- Protocol administration and governance
- Secure upgrade mechanisms

## User Journey

### For Suppliers (Lenders)

1. **Deposit Collateral**: Supply ETH/LINK to earn staking rewards
2. **Automatic Staking**: Assets automatically stake across LST protocols
3. **Earn Rewards**: Receive staking rewards while maintaining borrowing capacity
4. **Withdraw**: Unstake and withdraw assets at any time (subject to utilization)

### For Borrowers

1. **Supply Collateral**: Deposit ETH/LINK as collateral
2. **Borrow EUR**: Take loans against collateral up to LTV limits
3. **Manage Position**: Monitor health factor and collateral ratio
4. **Repay**: Repay loans to unlock collateral

### For EUR Suppliers

1. **Supply EUR**: Deposit EUR stablecoins to earn lending interest
2. **Earn Interest**: Receive interest from borrowers
3. **Withdraw**: Withdraw supplied EUR plus accrued interest

## Risk Management

### Collateral Management

- Dynamic LTV ratios based on asset volatility
- Liquidation thresholds to protect lenders
- Supply and borrow caps to limit exposure

### Liquidation System

- Automated liquidation when health factor < 1.0
- Liquidation bonuses to incentivize liquidators
- Partial liquidation limits (50% max per transaction)

### Oracle Security

- Chainlink price feeds for reliable pricing
- Price deviation monitoring
- Circuit breakers for extreme market conditions

## Benefits

### For Users

- **Capital Efficiency**: Earn staking rewards while borrowing
- **EUR Exposure**: Access to EUR-denominated lending
- **Diversification**: Spread risk across multiple LST protocols
- **Flexibility**: Borrow against multiple collateral types

### For the Ecosystem

- **Liquidity**: Deep liquidity pools for EUR stablecoins
- **Innovation**: Novel combination of lending + staking
- **Accessibility**: Simplified DeFi experience
- **Composability**: Integrates with existing DeFi protocols

## Supported Assets

### Collateral Assets

- **ETH**: Native Ethereum with LST staking
- **LINK**: Chainlink token with staking rewards

### Debt Assets

- **EURC**: Circle's EUR stablecoin
- **EURI**: Additional EUR stablecoins (extensible)

### Liquid Staking Protocols

- **Lido**: stETH integration
- **RocketPool**: rETH integration
- **EtherFi**: eETH integration
- **Morpho**: Morpho vault integration
- **StakeLink**: LINK staking integration

## Next Steps

This overview provides a high-level understanding of ZEUR protocol. For detailed technical information, please refer to the specific concept documents:

- [Core Concepts](./02-core-concepts.md)
- [Tokenization System](./03-tokenization-system.md)
- [Collateral Management](./04-collateral-management.md)
- [Borrowing and Lending](./05-borrowing-lending.md)
- [Liquidation Process](./06-liquidation-process.md)
- [Oracle Integration](./07-oracle-integration.md)
- [Vault and Staking](./08-vault-staking.md)
- [Access Management](./09-access-management.md)
- [Security Features](./10-security-features.md)
