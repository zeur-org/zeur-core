# VaultManager Documentation

## Overview

The **VaultManager** (implemented as `ProtocolVaultManager`) is the central automation hub of the Zeur protocol, orchestrating yield generation and management across multiple liquid staking protocols. It serves as the bridge between automated systems and the protocol's vault infrastructure, enabling intelligent yield optimization and distribution.

The contract integrates with two key automation systems:

- **ElizaOS**: AI-powered intelligent rebalancing between staking protocols
- **Chainlink Automation**: Decentralized keepers for yield harvesting and distribution

## Architecture

### Contract Structure

- **Inheritance**: `Initializable`, `AccessManagedUpgradeable`, `UUPSUpgradeable`, `IProtocolVaultManager`
- **Storage**: ERC-7201 namespaced storage with Pool contract reference
- **Access Control**: Role-based permissions for automated systems

### Storage Schema

```solidity
struct ProtocolVaultManagerStorage {
    IPool _pool; // Reference to main Pool contract
}
```

### Key Constants

- **Uniswap Pool Fee**: 100 (0.01% fee tier)
- **Swap Deadline**: 300 seconds (5 minutes)
- **Storage Slot**: `0x2df4395fe5d68f5ba01527b319bbde00044e704b1248be80415e6ccfb1598c00`

## Automation Integration Summary

### ElizaOS Integration

**Purpose**: AI-powered intelligent rebalancing between liquid staking protocols to optimize yield and manage risk.

**Key Capabilities**:

- Analyzes yield rates across different staking protocols (Lido, RocketPool, etc.)
- Assesses protocol risks and market conditions
- Makes automated rebalancing decisions to optimize returns
- Executes rebalancing transactions when beneficial

### Chainlink Automation Integration

**Purpose**: Decentralized automation for yield harvesting and distribution operations.

**Key Capabilities**:

- **Yield Harvesting**: Automatically claims staking rewards, swaps them to EURC via Uniswap, and deposits to colEUR
- **Yield Distribution**: Periodically distributes accumulated yield to the protocol treasury
- **Monitoring**: Tracks conditions and triggers automation when thresholds are met

## VaultManager Contract Functions

### 1. `rebalance(address vault, address fromRouter, address toRouter, uint256 amount)`

**Access**: `restricted` (ElizaOS agents)

**Purpose**: Rebalances LST positions between different staking protocols.

**Parameters**:

- `vault`: The vault contract holding the LST tokens
- `fromRouter`: Source staking router to unstake from (e.g., Lido, RocketPool)
- `toRouter`: Destination staking router to stake into
- `amount`: Amount of LST tokens or ETH to move between protocols

**Process**:

1. Validates both routers are registered
2. Calls `vault.rebalance()` to execute the rebalancing
3. Emits `PositionRebalanced` event

**Events**:

```solidity
event PositionRebalanced(
    address indexed fromVault,
    address indexed fromRouter,
    address indexed toRouter,
    uint256 amount
);
```

### 2. `distributeYield(address asset, uint256 amount)`

**Access**: `restricted` (Chainlink Keepers)

**Purpose**: Distributes accumulated yield to the protocol treasury.

**Parameters**:

- `asset`: The debt asset to distribute yield from (e.g., EURC)
- `amount`: Amount of yield to distribute (if 0, uses entire contract balance)

**Process**:

1. Validates asset is a registered debt asset
2. Gets corresponding colToken from debt configuration
3. Transfers yield amount to colToken
4. Emits `YieldDistributed` event

**Events**:

```solidity
event YieldDistributed(
    address indexed router,
    address indexed debtAsset,
    address indexed colToken,
    uint256 debtReceived
);
```

**Errors**:

- `ProtocolVaultManager__NotDebtAsset(asset)`: When asset is not a valid debt asset

### 3. `harvestYield(address fromVault, address router, address debtAsset, address swapRouter)`

**Access**: `restricted` (Chainlink Keepers)

**Purpose**: Harvests staking rewards and swaps them to debt assets.

**Parameters**:

- `fromVault`: Vault contract holding the LST tokens
- `router`: Staking router to harvest yield from
- `debtAsset`: Target debt asset to swap yield to (e.g., EURC)
- `swapRouter`: DEX router for swapping (e.g., Uniswap)

**Returns**: `uint256 debtReceived` - Amount of debt tokens received

**Process**:

1. Validates debt asset is registered
2. Calls `vault.harvestYield(router)` to extract LST yield
3. Approves LST for swap router
4. Executes Uniswap V3 swap: LST → debt asset
5. Transfers swapped tokens directly to colToken
6. Emits `YieldDistributed` event

**Swap Configuration**:

```solidity
ISwapRouter.ExactInputSingleParams({
    tokenIn: lstToken,
    tokenOut: debtAsset,
    fee: 100, // 0.01% pool
    recipient: colToken,
    deadline: block.timestamp + 300,
    amountIn: yieldAmount,
    amountOutMinimum: 0, // Production needs slippage protection
    sqrtPriceLimitX96: 0
});
```

**Events**:

```solidity
event YieldDistributed(
    address indexed router,
    address indexed debtAsset,
    address indexed colToken,
    uint256 debtReceived
);
```

**Errors**:

- `ProtocolVaultManager__NotDebtAsset(debtAsset)`: Invalid debt asset
- `ProtocolVaultManager__HarvestYieldFailed(router, debtAsset, swapRouter)`: Swap failure

### 4. `initialize(address initialAuthority, address pool)`

**Access**: `initializer`

**Purpose**: Initializes the contract with access control and pool reference.

**Parameters**:

- `initialAuthority`: Access manager contract address
- `pool`: Main Pool contract address

**Process**:

1. Initializes access control
2. Sets up UUPS upgradeability
3. Stores pool contract reference

## Access Control & Security

### Role-Based Permissions

```solidity
modifier restricted() {
    _checkCanCall(msg.sender, msg.data);
    _;
}
```

**Permission Structure**:

- **ElizaOS Agent**: `rebalance()` function access
- **Chainlink Keepers**: `distributeYield()` and `harvestYield()` access
- **Protocol Admin**: Emergency controls and upgrades

### Risk Mitigation

- **Router Validation**: Only whitelisted staking protocols
- **Asset Validation**: Only registered debt assets
- **Atomic Operations**: Prevent partial failures
- **Error Handling**: Graceful failure recovery
- **Circuit Breakers**: Emergency pause capabilities

## Configuration

### Initialization

```solidity
function initialize(
    address initialAuthority,  // Access manager contract
    address pool              // Main Pool contract
) public initializer
```

### Role Setup

```solidity
// Grant ElizaOS rebalancing permissions
accessManager.grantRole(REBALANCER_ROLE, elizaOSAgent, executionDelay);

// Grant Chainlink keeper permissions
accessManager.grantRole(YIELD_KEEPER_ROLE, chainlinkKeeper, executionDelay);
```

### Chainlink Automation Setup

```javascript
// Yield Distribution Upkeep
{
  target: protocolVaultManagerAddress,
  executeGas: 200000,
  checkData: "0x",
  balance: linkBalance,
  admin: protocolAdmin
}

// Yield Harvesting Upkeep
{
  target: protocolVaultManagerAddress,
  executeGas: 500000, // Higher gas for swap operations
  checkData: harvestParameters,
  balance: linkBalance,
  admin: protocolAdmin
}
```

## Integration Examples

### ElizaOS Agent Call

```typescript
// AI determines optimal rebalancing
const tx = await vaultManager.rebalance(
  vaultETHAddress,
  lidoRouterAddress,
  rocketPoolRouterAddress,
  ethers.parseEther("100")
);
```

### Chainlink Keeper Execution

```solidity
// Keeper calls harvest when conditions are met
vaultManager.harvestYield(
  vaultETHAddress,
  lidoRouterAddress,
  eurcAddress,
  uniswapV3RouterAddress
);
```

## Events & Monitoring

All functions emit comprehensive events for monitoring automation performance, yield generation, and rebalancing activities. These events enable off-chain analytics and alert systems to track protocol health and optimization effectiveness.

The VaultManager serves as the critical automation layer enabling efficient yield generation while maintaining optimal risk-return profiles through intelligent automation systems.
