# ZEUR Oracle Integration

## Overview

The ZEUR protocol relies on accurate and reliable price data for all critical operations including collateral valuation, borrowing capacity calculation, liquidation triggers, and health factor monitoring. The protocol integrates with Chainlink oracles to ensure secure, decentralized, and tamper-resistant price feeds.

## Chainlink Oracle Manager

### Architecture

The `ChainlinkOracleManager` serves as the central hub for all price data:

```solidity
contract ChainlinkOracleManager is AccessManagedUpgradeable, UUPSUpgradeable {
    // Mapping from asset address to Chainlink aggregator
    mapping(address => AggregatorV3Interface) public priceFeeds;

    // Price validation parameters
    uint256 public maxPriceDeviation = 500; // 5% max deviation
    uint256 public stalenessTolerance = 3600; // 1 hour staleness tolerance

    function getAssetPrice(address asset) external view returns (uint256);
}
```

### Supported Price Feeds

#### ETH/USD Feed

- **Address**: Chainlink ETH/USD aggregator
- **Decimals**: 8
- **Update Frequency**: ~1 minute
- **Deviation Threshold**: 0.5%

#### LINK/USD Feed

- **Address**: Chainlink LINK/USD aggregator
- **Decimals**: 8
- **Update Frequency**: ~1 minute
- **Deviation Threshold**: 0.5%

#### EURC/USD Feed

- **Address**: Chainlink EUR/USD aggregator (converted for EURC)
- **Decimals**: 8
- **Update Frequency**: ~1 minute
- **Deviation Threshold**: 0.1%

## Price Feed Integration

### Getting Asset Prices

The oracle manager provides a unified interface for price queries:

```solidity
function getAssetPrice(address asset) external view returns (uint256) {
    AggregatorV3Interface priceFeed = priceFeeds[asset];
    require(address(priceFeed) != address(0), "Price feed not found");

    (
        uint80 roundId,
        int256 price,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) = priceFeed.latestRoundData();

    // Validate price data
    require(price > 0, "Invalid price");
    require(updatedAt > 0, "Price not updated");
    require(block.timestamp - updatedAt <= stalenessTolerance, "Price data stale");
    require(answeredInRound >= roundId, "Stale round data");

    return uint256(price);
}
```

### Price Validation

Multiple validation checks ensure price reliability:

#### 1. Staleness Check

```solidity
require(block.timestamp - updatedAt <= stalenessTolerance, "Price data stale");
```

#### 2. Positive Price Check

```solidity
require(price > 0, "Invalid price");
```

#### 3. Round Consistency Check

```solidity
require(answeredInRound >= roundId, "Stale round data");
```

#### 4. Deviation Check (Optional)

```solidity
function validatePriceDeviation(uint256 newPrice, uint256 lastPrice) internal view {
    uint256 deviation = newPrice > lastPrice ?
        ((newPrice - lastPrice) * 10000) / lastPrice :
        ((lastPrice - newPrice) * 10000) / lastPrice;

    require(deviation <= maxPriceDeviation, "Price deviation too high");
}
```

## Price Calculations

### Collateral Value Calculation

Converting token amounts to USD values:

```solidity
function calculateCollateralValue(
    address asset,
    uint256 amount
) internal view returns (uint256) {
    uint256 price = oracleManager.getAssetPrice(asset);
    uint256 decimals = IERC20Metadata(asset).decimals();

    // Convert to USD value (8 decimal precision)
    return (amount * price) / (10 ** decimals);
}
```

**Example:**

- Asset: 5 ETH (18 decimals)
- Price: 300000000000 (8 decimals, $3,000.00)
- Value: (5 × 10^18 × 3000 × 10^8) / 10^18 = $15,000 × 10^8

### Debt Value Calculation

Converting debt amounts to USD values:

```solidity
function calculateDebtValue(
    address debtAsset,
    uint256 debtAmount
) internal view returns (uint256) {
    uint256 price = oracleManager.getAssetPrice(debtAsset);
    uint256 decimals = IERC20Metadata(debtAsset).decimals();

    return (debtAmount * price) / (10 ** decimals);
}
```

### Health Factor Calculation

Using oracle prices for health factor:

```solidity
function calculateHealthFactor(address user) internal view returns (uint256) {
    uint256 totalCollateralValue = 0;
    uint256 totalDebtValue = 0;
    uint256 weightedLiquidationThreshold = 0;

    // Calculate collateral values
    address[] memory collateralAssets = getCollateralAssets();
    for (uint i = 0; i < collateralAssets.length; i++) {
        uint256 balance = getUserCollateralBalance(user, collateralAssets[i]);
        if (balance > 0) {
            uint256 value = calculateCollateralValue(collateralAssets[i], balance);
            uint256 threshold = getCollateralConfiguration(collateralAssets[i]).liquidationThreshold;

            totalCollateralValue += value;
            weightedLiquidationThreshold += value * threshold;
        }
    }

    // Calculate debt values
    address[] memory debtAssets = getDebtAssets();
    for (uint i = 0; i < debtAssets.length; i++) {
        uint256 balance = getUserDebtBalance(user, debtAssets[i]);
        if (balance > 0) {
            totalDebtValue += calculateDebtValue(debtAssets[i], balance);
        }
    }

    if (totalDebtValue == 0) return type(uint256).max;
    if (totalCollateralValue == 0) return 0;

    uint256 avgLiquidationThreshold = weightedLiquidationThreshold / totalCollateralValue;
    return (totalCollateralValue * avgLiquidationThreshold) / (totalDebtValue * 100);
}
```

## Liquidation Price Calculations

### Liquidation Threshold Prices

Calculate the price at which liquidation becomes possible:

```solidity
function calculateLiquidationPrice(
    address user,
    address collateralAsset
) external view returns (uint256) {
    UserAccountData memory userData = getUserAccountData(user);
    uint256 collateralBalance = getUserCollateralBalance(user, collateralAsset);

    if (collateralBalance == 0 || userData.totalDebtValue == 0) {
        return 0;
    }

    uint256 liquidationThreshold = getCollateralConfiguration(collateralAsset).liquidationThreshold;

    // Price at which health factor = 1.0
    // (collateral_amount * price * threshold) / debt_value = 1.0
    // price = debt_value / (collateral_amount * threshold)

    return (userData.totalDebtValue * 10000 * (10 ** IERC20Metadata(collateralAsset).decimals())) /
           (collateralBalance * liquidationThreshold);
}
```

## Multi-Asset Price Management

### Batch Price Updates

For gas efficiency, prices can be queried in batches:

```solidity
function getMultipleAssetPrices(
    address[] calldata assets
) external view returns (uint256[] memory prices) {
    prices = new uint256[](assets.length);

    for (uint i = 0; i < assets.length; i++) {
        prices[i] = getAssetPrice(assets[i]);
    }
}
```

### Price Aggregation

For portfolio-level calculations:

```solidity
function calculatePortfolioValue(
    address[] calldata assets,
    uint256[] calldata amounts
) external view returns (uint256 totalValue) {
    require(assets.length == amounts.length, "Array length mismatch");

    for (uint i = 0; i < assets.length; i++) {
        uint256 assetValue = calculateCollateralValue(assets[i], amounts[i]);
        totalValue += assetValue;
    }
}
```

## Oracle Security Features

### Circuit Breakers

Automatic protection against extreme price movements:

```solidity
mapping(address => uint256) public lastValidPrice;
mapping(address => uint256) public lastUpdateTime;

function getAssetPriceWithCircuitBreaker(address asset) external view returns (uint256) {
    uint256 currentPrice = getAssetPrice(asset);
    uint256 lastPrice = lastValidPrice[asset];

    if (lastPrice > 0) {
        uint256 deviation = currentPrice > lastPrice ?
            ((currentPrice - lastPrice) * 10000) / lastPrice :
            ((lastPrice - currentPrice) * 10000) / lastPrice;

        // If deviation > 10%, use time-weighted average
        if (deviation > 1000) {
            return calculateTimeWeightedPrice(asset);
        }
    }

    return currentPrice;
}
```

### Fallback Oracles

Secondary price sources for redundancy:

```solidity
mapping(address => AggregatorV3Interface) public fallbackPriceFeeds;

function getAssetPriceWithFallback(address asset) external view returns (uint256) {
    try this.getAssetPrice(asset) returns (uint256 price) {
        return price;
    } catch {
        // Try fallback oracle
        return getFallbackPrice(asset);
    }
}
```

### Time-Weighted Average Price (TWAP)

Smooth price movements using TWAP:

```solidity
struct PriceHistory {
    uint256 price;
    uint256 timestamp;
}

mapping(address => PriceHistory[]) public priceHistory;

function calculateTWAP(
    address asset,
    uint256 duration
) external view returns (uint256) {
    PriceHistory[] memory history = priceHistory[asset];
    uint256 cutoffTime = block.timestamp - duration;

    uint256 weightedSum = 0;
    uint256 totalWeight = 0;

    for (uint i = history.length - 1; i >= 0; i--) {
        if (history[i].timestamp < cutoffTime) break;

        uint256 weight = history[i].timestamp - cutoffTime;
        weightedSum += history[i].price * weight;
        totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0;
}
```

## Oracle Administration

### Adding New Price Feeds

```solidity
function addPriceFeed(
    address asset,
    address priceFeed
) external restricted {
    require(asset != address(0), "Invalid asset");
    require(priceFeed != address(0), "Invalid price feed");

    // Validate price feed works
    AggregatorV3Interface feed = AggregatorV3Interface(priceFeed);
    (, int256 price,,,) = feed.latestRoundData();
    require(price > 0, "Price feed validation failed");

    priceFeeds[asset] = feed;
    emit PriceFeedAdded(asset, priceFeed);
}
```

### Updating Oracle Parameters

```solidity
function updateOracleParameters(
    uint256 _maxPriceDeviation,
    uint256 _stalenessTolerance
) external restricted {
    require(_maxPriceDeviation <= 2000, "Max deviation too high"); // 20% max
    require(_stalenessTolerance >= 300, "Staleness tolerance too low"); // 5 min minimum

    maxPriceDeviation = _maxPriceDeviation;
    stalenessTolerance = _stalenessTolerance;

    emit OracleParametersUpdated(_maxPriceDeviation, _stalenessTolerance);
}
```

### Emergency Price Override

For extreme situations:

```solidity
mapping(address => uint256) public emergencyPrices;
mapping(address => bool) public emergencyMode;

function setEmergencyPrice(
    address asset,
    uint256 price
) external restricted {
    require(price > 0, "Invalid emergency price");

    emergencyPrices[asset] = price;
    emergencyMode[asset] = true;

    emit EmergencyPriceSet(asset, price);
}
```

## Error Handling

### Oracle-Related Errors

```solidity
error Oracle_PriceFeedNotFound(address asset);
error Oracle_InvalidPrice(address asset, int256 price);
error Oracle_StalePrice(address asset, uint256 lastUpdate);
error Oracle_PriceDeviationTooHigh(address asset, uint256 deviation);
error Oracle_RoundDataInconsistent(address asset);
```

### Graceful Degradation

When oracles fail:

1. **Use Fallback Oracles**: Secondary price sources
2. **Use TWAP**: Time-weighted average prices
3. **Pause Operations**: Temporarily halt sensitive operations
4. **Emergency Prices**: Manual price overrides

## Gas Optimization

### Efficient Price Queries

```solidity
// Cache prices for multiple uses within same transaction
mapping(address => uint256) private priceCache;
mapping(address => uint256) private cacheTimestamp;

function getCachedPrice(address asset) internal returns (uint256) {
    if (cacheTimestamp[asset] != block.timestamp) {
        priceCache[asset] = getAssetPrice(asset);
        cacheTimestamp[asset] = block.timestamp;
    }
    return priceCache[asset];
}
```

### Batch Price Operations

Optimize gas when working with multiple assets:

```solidity
function batchCalculateValues(
    address[] calldata assets,
    uint256[] calldata amounts
) external view returns (uint256[] memory values) {
    values = new uint256[](assets.length);

    for (uint i = 0; i < assets.length; i++) {
        values[i] = calculateCollateralValue(assets[i], amounts[i]);
    }
}
```

## Monitoring and Alerts

### Price Deviation Monitoring

```solidity
event PriceDeviation(
    address indexed asset,
    uint256 oldPrice,
    uint256 newPrice,
    uint256 deviation
);

event StalePriceDetected(
    address indexed asset,
    uint256 lastUpdate,
    uint256 staleness
);
```

### Oracle Health Monitoring

```solidity
function checkOracleHealth(address asset) external view returns (bool healthy) {
    try this.getAssetPrice(asset) returns (uint256) {
        return true;
    } catch {
        return false;
    }
}
```

The oracle integration system provides the reliable and secure price data foundation that enables all ZEUR protocol operations while maintaining appropriate safeguards against oracle manipulation and failures.
