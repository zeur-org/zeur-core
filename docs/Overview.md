# Zeur Light Paper

This documentation describes the Zeur platform, zero-interest lending protocol for MiCA-compliant EUR stablecoins built for the European crypto market.

## Project Layout

Zeur documentation is organized into the following sections:

- **Concepts** – General principles behind Zeur, such as zero-interest design, automated swap-repay, and vault strategy.
- **Contracts** – Smart contract systems powering Zeur (ZeurVault, ZeurLending, AutomationExecutors).
- **SDKs** – SDKs or libraries for interacting with Zeur (planned).
- **APIs** – APIs for querying user positions, liquidation status, vault stats (planned).

Each section should include:

- Overview
- Guides
- Technical Reference

## Overview

Each product overview should explain:

- **High-level components:**
  Vault system, Euro-backed stablecoin lending (EURC, EURI), automation bots (stop-loss / take-profit), and spot swap-repay modules.
- **High-level functionality:**
  Zero-interest crypto-backed loans, real-time vault tracking, auto-repay with profit extraction, permissionless stop-loss.
- **Source code location:**
  [Zeur GitHub Repository](https://github.com/zeur-org/zeur-core)
- **Artifacts:**
  Smart contracts (on Etherscan/Sepolia), SDK/JS package (planned)

Example: `/contracts/zeurVault/overview` – provides an intro to our main vault engine.

## Guides

Guides should follow this structure:

### Principles

- A single reusable concept per guide (e.g., setting a stop-loss, initiating a loan)
- Three parts:

  1. **Introduction** – Explain the concept & purpose
  2. **Step-by-step code walkthrough**
  3. **Expected outcome** – E.g., verify your vault updated correctly

### Example Guide Ideas:

| Title                        | Description                                         |
| ---------------------------- | --------------------------------------------------- |
| Getting Your First Zeur Loan | Borrow EURC against ETH collateral with 0% interest |
| Setting a Stop-Loss          | Set automatic repayment if the price drops          |
| Triggering a Take-Profit     | Lock in gains with auto-deleveraging                |
| Spot Swap-Repay              | Instantly repay by swapping collateral to EURC      |
| Deploying a Vault via SDK    | How to integrate vault creation in dApps            |

All guides will reference live code examples from the Zeur example repo.

## Technical Reference

Each module or SDK should have its exported interfaces documented. This can be generated using:

- `solidity-docgen` for smart contracts
- `typedoc` for any TypeScript SDKs

Example:

- `/contracts/zeurVault/reference` – Documented functions, structs, and events
- `/sdk/zeur-js/reference` – Coming soon

## How to Create Technical Reference

### Solidity Contracts

```bash
npm install solidity-docgen
npm install -D solc-0.8@npm:solc@0.8.21
npx solidity-docgen --solc-module solc-0.8 -t ./templates
```

### TypeScript SDK

```bash
npm install --save-dev typedoc typedoc-plugin-markdown
npx typedoc --out docs src/index.ts
```

## Updating Search Indices with Algolia

1. Create `.env` with `APPLICATION_ID` and `API_KEY`
2. Update `config.json` with your:

   - `start_url`: [https://zeur.gitbook.io/zeur](https://zeur.gitbook.io/zeur)
   - `index_name`: `zeur-docs`

3. Run:

```bash
docker run -it --env-file=.env -e "CONFIG=$(cat ./config.json | jq -r tostring)" algolia/docsearch-scraper
```

## Installation

```bash
yarn install
```

## Local Development

```bash
yarn run start
```

## Clear Cache

```bash
yarn docusaurus clear
```

## Build

```bash
yarn build
```

## Deployment

Deployed automatically via Vercel on `main` branch merge.
