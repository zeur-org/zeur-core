# PoolData

## PoolData Interface

A single entry point to fetch **market-level** and **user-level** data in one call. All getters are `view`/`pure` and return fully populated structs, so the UI only needs to hit this contract.

---

## Main Getter Functions

```ts
// Lists
getCollateralAssetList(): address[]
getDebtAssetList():       address[]

// Asset details
getAssetData(asset: address):        AssetData

// User details
getUserData(user: address):          UserData
```

- **`getAssetData`**: Best for market dashboards—shows caps, usage, rates, LST breakouts.
- **`getUserData`**: Best for wallet overviews—shows you exactly what the user has supplied, borrowed, and their health.
- Use the **configuration getters** if you need to render admin or settings pages—the UI can display or allow toggling of LTV, caps, pause/freeze.

---

### AssetType

```solidity
enum AssetType {
  Collateral, // e.g. ETH, LINK
  Debt        // e.g. EURC, EURI
}
```

Indicates whether an asset is used **only** as collateral, or **only** as a borrowable stablecoin.

---

## Structs & Their Fields

### AssetData

Returned by `getAssetData(asset)`; combines configuration + live metrics, standardized for both collateral and debt assets.

| Field                    | Type                | Description                                                                    | Collateral | Debt |
| ------------------------ | ------------------- | ------------------------------------------------------------------------------ | ---------- | ---- |
| `assetType`              | `AssetType`         | Collateral vs. Debt                                                            | ✅         | ✅   |
| `asset`                  | `address`           | Underlying token address                                                       | ✅         | ✅   |
| `price`                  | `uint256`           | Current price from Chainlink oracle (8 decimals, USD)                          | ✅         | ✅   |
| `supplyCap`              | `uint256`           | Max total that can be supplied into this market                                | ✅         | ✅   |
| `borrowCap`              | `uint256`           | Max total that can be borrowed (for debt) or borrowed against (for collateral) | ✅         | ✅   |
| `totalSupply`            | `uint256`           | Current total supplied                                                         | ✅         | ✅   |
| `totalBorrow`            | `uint256`           | Current total borrowed (only for debt assets)                                  | ❌         | ✅   |
| `totalShares`            | `uint256`           | Total ERC-4626 shares outstanding (for debt vaults)                            | ❌         | ✅   |
| `utilizationRate`        | `uint256`           | `totalBorrow / totalSupply` (scaled 1e18) (only debt)                          | ❌         | ✅   |
| `supplyRate`             | `uint256`           | Current APR for suppliers, in basis points (bps)                               | ❌         | ✅   |
| `borrowRate`             | `uint256`           | Current APR for borrowers, in bps (will be zero in zero-interest markets)      | ❌         | ✅   |
| `ltv`                    | `uint16`            | Loan-to-Value ratio, in bps (e.g. 7500 = 75%) (only collateral)                | ✅         | ❌   |
| `liquidationThreshold`   | `uint16`            | When health factor < 1 (only collateral)                                       | ✅         | ❌   |
| `liquidationBonus`       | `uint16`            | Bonus paid to liquidator, in bps (only collateral)                             | ✅         | ❌   |
| `liquidationProtocolFee` | `uint16`            | Fee portion of bonus flowing to protocol treasury, in bps (only collateral)    | ✅         | ❌   |
| `reserveFactor`          | `uint16`            | Portion of interest/yield skimmed to protocol, in bps                          | ✅         | ❌   |
| `decimals`               | `uint8`             | ERC-20 decimals of the underlying asset                                        | ✅         | ✅   |
| `isFrozen`               | `bool`              | Users can’t supply/borrow, but can withdraw/repay/liquidate                    | ✅         | ✅   |
| `isPaused`               | `bool`              | All operations disabled (supply/withdraw/repay/borrow/liquidate)               | ✅         | ✅   |
| `stakedTokens`           | `StakedTokenData[]` | For collateral assets only: per-protocol LST breakdown (stETH, rETH, etc.)     | ✅         | ❌   |

---

### StakedTokenData

Describes how a collateral asset (ETH or LINK) is distributed across liquid-staking protocols.

| Field              | Type      | Description                                                                                        |
| ------------------ | --------- | -------------------------------------------------------------------------------------------------- |
| `stakedToken`      | `address` | LST token address (e.g. stETH, rETH, mETH, stLINK)                                                 |
| `underlyingAmount` | `uint256` | How much of the original asset is represented by this staking protocol (in underlying token units) |
| `stakedAmount`     | `uint256` | How many LST tokens the protocol actually holds                                                    |

---

### UserData

Returned by `getUserData(user)`; aggregates totals plus per-asset breakdown.

| Field                         | Type                   | Description                                                                    |
| ----------------------------- | ---------------------- | ------------------------------------------------------------------------------ |
| `totalCollateralValue`        | `uint256`              | Sum of all collateral (in base currency USD)                                   |
| `totalDebtValue`              | `uint256`              | Sum of all debt (in USD)                                                       |
| `availableBorrowsValue`       | `uint256`              | How much more the user can still borrow (in USD)                               |
| `currentLiquidationThreshold` | `uint256`              | Weighted average threshold across enabled collateral                           |
| `ltv`                         | `uint256`              | Weighted average LTV across enabled collateral                                 |
| `healthFactor`                | `uint256`              | = `(collateralValue × threshold) / debtValue` (18-decimals; <1 → liquidatable) |
| `userCollateralData`          | `UserCollateralData[]` | Per-asset collateral balances                                                  |
| `userDebtData`                | `UserDebtData[]`       | Per-asset debt balances (supply & borrowed)                                    |

---

### UserCollateralData

| Field             | Type      | Description                      |
| ----------------- | --------- | -------------------------------- |
| `collateralAsset` | `address` | Token address                    |
| `supplyBalance`   | `uint256` | User’s collateral deposit amount |

---

### UserDebtData

| Field           | Type      | Description                                       |
| --------------- | --------- | ------------------------------------------------- |
| `debtAsset`     | `address` | Debt token address (EURC, EURI)                   |
| `supplyBalance` | `uint256` | How much stablecoin the user supplied as lender   |
| `borrowBalance` | `uint256` | How much stablecoin the user borrowed as borrower |

---

### CollateralConfiguration & DebtConfiguration

Normally, you don't need to use these getters. The getAssetData() function already returns the configuration of the asset. These getters let you pull **raw on-chain settings** if you need lower-level data (e.g. in governance UIs):

```solidity
// Single-asset getters
function getCollateralAssetConfiguration(address asset)
  returns (CollateralConfiguration memory);

function getDebtAssetConfiguration(address asset)
  returns (DebtConfiguration memory);

// Batch getters
function getCollateralAssetsConfiguration(address[] memory assets)
	returns (CollateralConfiguration[] memory);

function getDebtAssetsConfiguration(address[] memory assets)
	returns (DebtConfiguration[] memory);
```

```ts
getCollateralAssetConfiguration(asset):   CollateralConfiguration
getDebtAssetConfiguration(asset):         DebtConfiguration

getCollateralAssetsConfiguration(assets):   CollateralConfiguration[]
getDebtAssetsConfiguration(assets):         DebtConfiguration[]
```

---

### CollateralConfiguration

| Field                    | Type      | Description                                                    |
| ------------------------ | --------- | -------------------------------------------------------------- |
| `supplyCap`              | `uint256` | Maximum total that can be supplied into this collateral market |
| `borrowCap`              | `uint256` | Maximum total that can be borrowed against this collateral     |
| `colToken`               | `address` | Collateral token address                                       |
| `tokenVault`             | `address` | Vault contract managing this collateral                        |
| `ltv`                    | `uint16`  | Loan-to-Value ratio in basis points (e.g. 7500 = 75%)          |
| `liquidationThreshold`   | `uint16`  | Liquidation threshold in basis points (e.g. 8000 = 80%)        |
| `liquidationBonus`       | `uint16`  | Liquidation bonus in basis points (e.g. 10500 = 5% bonus)      |
| `liquidationProtocolFee` | `uint16`  | Protocol fee on liquidation bonus in bps (e.g. 1000 = 10%)     |
| `reserveFactor`          | `uint16`  | Reserve factor in basis points (e.g. 1000 = 10%)               |
| `isFrozen`               | `bool`    | Whether new supply/borrow operations are frozen                |
| `isPaused`               | `bool`    | Whether all operations are paused                              |

---

### DebtConfiguration

| Field           | Type      | Description                                              |
| --------------- | --------- | -------------------------------------------------------- |
| `supplyCap`     | `uint256` | Maximum total that can be supplied into this debt market |
| `borrowCap`     | `uint256` | Maximum total that can be borrowed from this debt market |
| `colToken`      | `address` | Collateral token address associated with this debt       |
| `debtToken`     | `address` | Debt token address                                       |
| `reserveFactor` | `uint16`  | Reserve factor in basis points (e.g. 1000 = 10%)         |
| `isFrozen`      | `bool`    | Whether new supply/borrow operations are frozen          |
| `isPaused`      | `bool`    | Whether all operations are paused                        |

Both configurations include caps, token addresses, rates (LTV, fees), and pause/freeze flags.

---

### Integration Tips

- **Batch Calls**: Fetch `getCollateralAssetList()` once, then map `getAssetData(asset)` across it.
- **Pagination**: If you have many assets, you can page through the list in chunks.
- **Decimal Handling**: All amounts and rates use 18-decimals or bps units—convert to human-friendly `%` or token units in the front end.
- **Data Refresh**: Call these getters on block events or when user switches accounts; no caching needed on-chain.
