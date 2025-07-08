# The Idea: A Zero-Interest Loan Protocol
Our protocol is a decentralized lending platform where users can borrow real-world value against their crypto assets without paying any interest.
Borrowers deposit yield-generating collateral like Ethereum (ETH), Chainlink (LINK), or Liquid Staking Tokens (LSTs) and in return, can borrow established, fiat-backed stablecoins like EURC.
Instead of charging borrowers interest, the protocol puts their collateral to work in trusted, low risk yield strategies (staking on Lido, Ether.fi, RocketPool, Morpho, etc.). The entire yield generated from this collateral is used to pay interest to the lenders who provided the EURC.

# Our Solution: A Bridge to Real-World Spending
Our protocol provides a direct solution by combining the best of all worlds:
- **For Borrowers**: Zero-Interest, No-Deadline Loans. Borrowers unlock liquidity from their assets without selling them. Since they pay no interest, they are not pressured by accumulating debt and can wait for the ideal time to repay, avoiding forced sales in a down market.
- **For Lenders**: High, Stable Yield on EUR. Lenders deposit EURC, a stablecoin with direct banking off-ramps. Because of the overcollateralization model (e.g., 66% LTV means every €100 borrowed is backed by over €150 of collateral), the yield generated on the larger collateral base translates into a higher-than-market-rate APY on the lent EURC. This creates a strong incentive to lend a stablecoin that typically has few high-yield opportunities in DeFi.
We solve the "last-mile" problem by using a trusted, liquid stablecoin (EURC), making the journey from crypto collateral to cash in a bank account seamless.

# Key Features
1. **Zero-Interest Borrowing**: The core value proposition. Borrowers' debt does not grow over time.
2. **Yield-Forwarding Mechanism**: The protocol automatically deploys collateral into audited, blue-chip yield strategies. The harvested yield is then converted and paid directly to EURC lenders.
3. **Fiat-Backed Stablecoin Focus (EURC)**: We use established, regulated stablecoins. This ensures immediate real-world utility, high liquidity, and straightforward on/off-ramping for users.
4. **Automate Yield distribution**: We use Chainlink Automation to automate distributing yield to ERC4626 Vault.
