## The Problem We Solve

Many crypto holders, particularly in Europe, view their assets as long-term investments. They don't want to sell, which would trigger a taxable event and cause them to miss out on potential future appreciation. However, they often need cash for major life purchases like a down payment on a house, a car, or other significant expenses.

Their current options are very limited for real world spending:

1.  **Borrow from DeFi (Aave/Compound):** Traditional DeFi lending has variable, often high-interest rates that can exceed standard consumer loans (which are ~4-7% in Europe). This makes borrowing for real-world expenses unpredictable and potentially expensive.
2.  **Borrow from TradFi (Consumer/Mortgage Loan):** While rates can be lower (~3-5%), the process is slow, requires extensive paperwork, and doesn't recognize crypto as collateral.
3.  **Use other "Zero-Interest" Protocols:** Services like Alchemix or Liquity are innovative but force borrowers to take out loans in a new, protocol-specific stablecoin (like alUSD or LUSD ). These stablecoins lack the liquidity, trust, and direct off-ramps to be easily converted into Euros and used for real-life purchases.

Since we personnaly experienced this problem, we decided to build a protocol that would solve it.

## The Idea: A Zero-Interest Loan Protocol

Our protocol is a decentralized lending platform where users can borrow real-world value against their crypto assets without paying any interest.

- Borrowers deposit collateral like ETH (Ethereum), LINK (Chainlink ), AVAX (on Avalanche)
- Borrowers can borrow established, fiat-backed stablecoins like EURC with zero interest rate.
- The collateral is automatically staked in low-risk LST protocol (stable, organic yield from Lido, Ether.fi, RocketPool, etc.).
- The entire yield generated from this collateral is used to pay interest to the lenders who provided the EURC.

## Architecture

![image](https://assets.devfolio.co/content/528346628ae54b2c90419c38b3bf10c3/1a14368d-9489-40fe-a995-a0bec3fa7871.png)

- Pool: entry contract for users (supply, withdraw, borrow, repay, liquidate)
- Vaults: manage user deposited asset through Pool, interact with routers to stake asset in LST protocol. Each vault is isolated and can have different staking routers.
- StakingRouter: plug-and-play contract that have the same interface, but different logics for each LST protocol (Lido, Etherfi, RocketPool, StakeLink or lending market like Morpho on Ethereum, LST like Benqi on Avalanche)
- Tokenization: ColEURC/DebtEUR represent the user's supply/debt of EUR stablecoins, ColToken represents the user's collateral
- ChainlinkOracleManager: to get price of asset through Chainlink price feeds
- ProtocolVaultManager: dedicated contract with harvest/distribute yield and rebalance portfolio logics
- ProtocolSettingManager: dedicated contract with admin-level configurations for the pool
- ProtocolAccessManager: contract with admin-level access management for protocol
- Chainlink Automation: time-based keeper that execute distribute yield
- ElizaOS: offchain "brain" to monitor position, create strategy, execute rebalance

## Chainlink Technology

The protocol’s security and automation rely on the full Chainlink stack:

- Chainlink Price Feeds deliver real-time asset prices for safe LTV calculations, borrow/withdraw limits, and liquidations in the Pool contract.
  [ChainlinkOracleManager](https://github.com/zeur-org/zeur-core/blob/master/src/chainlink/ChainlinkOracleManager.sol)
  [Pool](https://github.com/zeur-org/zeur-core/blob/master/src/pool/Pool.sol)

- Chainlink Automation runs scheduled yield-harvest and distribution cycles, keeping payouts transparent and on time.
  [ProtocolVaultManager](https://github.com/zeur-org/zeur-core/blob/master/src/pool/manager/ProtocolVaultManager.sol)

- Chainlink Staking lets users post staked LINK as collateral, adding a new utility layer for the LINK community while reinforcing network security.
  [VaultLINK](https://github.com/zeur-org/zeur-core/blob/master/src/pool/vault/VaultLINK.sol)
  [StakingRouterLINK](https://github.com/zeur-org/zeur-core/blob/master/src/pool/router/StakingRouterLINK.sol)

### Key Features

1.  **Zero-Interest Borrowing:** The core value proposition. Borrowers' debt does not grow over time.
2.  **Yield-Forwarding Mechanism:** The protocol automatically deploys collateral into audited, blue-chip yield strategies. The harvested yield is then converted and paid directly to EURC lenders.
3.  **Fiat-Backed Stablecoin Focus (EURC):** We use established, regulated stablecoins. This ensures immediate real-world utility, high liquidity, and straightforward on/off-ramping for users.
4.  **Automate Yield distribution:** We use Chainlink Automation to automate distributing yield to ERC4626 Vault.
5.  **For Borrowers: Zero-Interest Loans.** Borrowers unlock liquidity from their assets without selling them. Since they pay no interest, they are not pressured by accumulating debt and can wait for the ideal time to repay, avoiding forced sales in a down market.
6.  **For Lenders: High, Stable Yield on EUR.** Lenders deposit EURC, a stablecoin with direct banking off-ramps. Because of the DeFi overcollateralization model (e.g., 66% LTV means every €100 borrowed is backed by over €150 of collateral), the yield generated on the larger collateral base translates into a higher-than-market-rate APY on the lent EURC.

### Smart contracts & Deployments

[Documentation](https://zeur.gitbook.io/zeur)

[Smart Contract Repo](https://github.com/zeur-org/zeur-core)

[Interface Repo](https://github.com/zeur-org/zeur-interface)

[ElizaOS Repo](https://github.com/zeur-org/zeur-elizaos)
