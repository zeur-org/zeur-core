# Access Management

## Overview

The ZEUR protocol implements a comprehensive access management system based on OpenZeppelin's AccessManager pattern. This system provides fine-grained role-based access control, time-delayed execution for critical operations, and decentralized governance capabilities while maintaining operational security.

## Architecture

### Core Components

#### 1. ProtocolAccessManager

Central access control contract managing all roles and permissions:

```solidity
contract ProtocolAccessManager is AccessManager {
    // Role definitions
    bytes32 public constant ADMIN_ROLE = 0x00;
    bytes32 public constant POOL_ADMIN_ROLE = keccak256("POOL_ADMIN_ROLE");
    bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");
    bytes32 public constant VAULT_ADMIN_ROLE = keccak256("VAULT_ADMIN_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
}
```

#### 2. AccessManagedUpgradeable

All protocol contracts inherit from AccessManagedUpgradeable:

```solidity
contract Pool is AccessManagedUpgradeable, UUPSUpgradeable {
    modifier restricted() {
        _checkCanCall(msg.sender, msg.data);
        _;
    }
}
```

### Access Control Flow

```
User Request → Contract Function → AccessManager Check → Execute or Revert
```

## Role Definitions

### 1. ADMIN_ROLE (Root Admin)

**Responsibilities:**

- Grant and revoke all other roles
- Update access manager configuration
- Emergency protocol controls
- Upgrade contract implementations

**Permissions:**

```solidity
// Can call any restricted function
function canCall(
    address caller,
    address target,
    bytes4 selector
) public view returns (bool) {
    return hasRole(ADMIN_ROLE, caller);
}
```

**Members:**

- Protocol multisig wallet
- DAO governance contract (future)

### 2. POOL_ADMIN_ROLE

**Responsibilities:**

- Configure asset parameters (LTV, liquidation thresholds)
- Set supply and borrow caps
- Freeze/unfreeze assets
- Manage interest rate models

**Key Functions:**

```solidity
function configureCollateralAsset(
    address asset,
    CollateralConfiguration memory config
) external restricted;

function configureDebtAsset(
    address asset,
    DebtConfiguration memory config
) external restricted;

function freezeCollateral(address asset, bool freeze) external restricted;
function pauseCollateral(address asset, bool pause) external restricted;
```

**Typical Members:**

- Protocol risk management team
- DAO risk committee
- Automated risk management contracts

### 3. ORACLE_ADMIN_ROLE

**Responsibilities:**

- Add and update price feeds
- Configure oracle parameters
- Set emergency prices
- Manage oracle security settings

**Key Functions:**

```solidity
function addPriceFeed(address asset, address priceFeed) external restricted;
function updateOracleParameters(uint256 deviation, uint256 staleness) external restricted;
function setEmergencyPrice(address asset, uint256 price) external restricted;
```

**Typical Members:**

- Oracle management team
- Automated oracle bots
- Emergency response team

### 4. VAULT_ADMIN_ROLE

**Responsibilities:**

- Configure staking strategies
- Manage vault parameters
- Rebalance staking allocations
- Update staking routers

**Key Functions:**

```solidity
function updateStakingStrategy(AllocationStrategy memory strategy) external restricted;
function addStakingRouter(address router) external restricted;
function rebalanceVault() external restricted;
```

**Typical Members:**

- Yield strategy team
- Automated rebalancing bots
- Vault managers

### 5. LIQUIDATOR_ROLE

**Responsibilities:**

- Execute liquidations
- Call liquidation functions
- Access liquidation incentives

**Key Functions:**

```solidity
function liquidate(
    address collateralAsset,
    address debtAsset,
    uint256 debtAmount,
    address from
) external restricted;
```

**Typical Members:**

- Liquidation bots
- MEV searchers
- Keeper networks
- Public (if open liquidations)

### 6. MINTER_ROLE

**Responsibilities:**

- Mint and burn tokens
- Exclusively for Pool contract
- Token supply management

**Key Functions:**

```solidity
function mint(address account, uint256 value) external restricted;
function burn(address account, uint256 value) external restricted;
```

**Typical Members:**

- Pool contract only
- Automated by protocol logic

### 7. PAUSER_ROLE

**Responsibilities:**

- Pause/unpause protocol operations
- Emergency response capabilities
- Circuit breaker activation

**Key Functions:**

```solidity
function pauseCollateral(address asset, bool pause) external restricted;
function pauseDebtAsset(address asset, bool pause) external restricted;
function emergencyPause() external restricted;
```

**Typical Members:**

- Emergency response team
- Automated monitoring systems
- Protocol guardians

### 8. EMERGENCY_ROLE

**Responsibilities:**

- Highest priority emergency actions
- Override normal operations
- Recovery mechanisms

**Key Functions:**

```solidity
function emergencyWithdraw(address asset, uint256 amount) external restricted;
function emergencySetPrice(address asset, uint256 price) external restricted;
function emergencyUpgrade(address newImplementation) external restricted;
```

**Typical Members:**

- Emergency multisig
- Incident response team
- Core development team

## Time-Delayed Execution

### Timelock Mechanism

Critical operations require time delays to allow community review:

```solidity
struct DelayedOperation {
    address target;
    bytes data;
    uint256 executeAfter;
    bool executed;
}

mapping(bytes32 => DelayedOperation) public delayedOperations;

uint256 public constant ADMIN_DELAY = 2 days;
uint256 public constant CONFIG_DELAY = 1 days;
uint256 public constant EMERGENCY_DELAY = 6 hours;
```

### Delayed Operation Types

#### 1. Administrative Changes (2 days)

- Role modifications
- Contract upgrades
- Major parameter changes

```solidity
function scheduleAdminOperation(
    address target,
    bytes calldata data
) external restricted returns (bytes32 operationId) {
    operationId = keccak256(abi.encode(target, data, block.timestamp));

    delayedOperations[operationId] = DelayedOperation({
        target: target,
        data: data,
        executeAfter: block.timestamp + ADMIN_DELAY,
        executed: false
    });

    emit OperationScheduled(operationId, target, data, block.timestamp + ADMIN_DELAY);
}
```

#### 2. Configuration Changes (1 day)

- Asset parameter updates
- Risk parameter adjustments
- Oracle configurations

#### 3. Emergency Operations (6 hours)

- Asset pausing
- Emergency price setting
- Circuit breaker activation

### Execution Process

```solidity
function executeDelayedOperation(bytes32 operationId) external {
    DelayedOperation storage op = delayedOperations[operationId];

    require(op.executeAfter != 0, "Operation not scheduled");
    require(block.timestamp >= op.executeAfter, "Operation not ready");
    require(!op.executed, "Operation already executed");

    op.executed = true;

    (bool success, bytes memory result) = op.target.call(op.data);
    require(success, "Operation execution failed");

    emit OperationExecuted(operationId, op.target, op.data);
}
```

## Multi-Signature Integration

### Primary Multisig Configuration

**ADMIN_ROLE Multisig:**

- **Threshold**: 3 of 5
- **Members**: Core team members
- **Responsibilities**: Protocol governance, upgrades, emergency response

**POOL_ADMIN_ROLE Multisig:**

- **Threshold**: 2 of 3
- **Members**: Risk management team
- **Responsibilities**: Day-to-day parameter management

### Multisig Operations

```solidity
interface IMultisig {
    function submitTransaction(
        address destination,
        uint256 value,
        bytes calldata data
    ) external returns (uint256 transactionId);

    function confirmTransaction(uint256 transactionId) external;
    function executeTransaction(uint256 transactionId) external;
}
```

## Governance Integration

### DAO Governance (Future)

Planned integration with DAO governance:

```solidity
contract DAOGovernor is Governor, GovernorSettings, GovernorCountingSimple {
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override returns (uint256);

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable override returns (uint256);
}
```

### Governance Process

1. **Proposal**: Community submits governance proposal
2. **Voting**: Token holders vote on proposal
3. **Execution**: Successful proposals execute with timelock
4. **Implementation**: Changes applied to protocol

## Security Features

### Role Separation

No single role has complete control:

```solidity
// Example: Oracle admin cannot pause protocol
function pauseProtocol() external {
    require(hasRole(PAUSER_ROLE, msg.sender), "Not authorized");
    // ORACLE_ADMIN_ROLE cannot call this
}
```

### Cross-Role Validation

Critical operations require multiple roles:

```solidity
function emergencyUpgrade(address newImplementation) external {
    require(
        hasRole(ADMIN_ROLE, msg.sender) || hasRole(EMERGENCY_ROLE, msg.sender),
        "Insufficient permissions"
    );

    // Additional validation for emergency role
    if (hasRole(EMERGENCY_ROLE, msg.sender) && !hasRole(ADMIN_ROLE, msg.sender)) {
        require(isEmergencyActive(), "Emergency not active");
    }
}
```

### Audit Trail

All access control operations are logged:

```solidity
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
event OperationScheduled(bytes32 indexed operationId, address target, bytes data, uint256 executeAfter);
event OperationExecuted(bytes32 indexed operationId, address target, bytes data);
event EmergencyActionTaken(address indexed caller, bytes4 indexed selector, bytes data);
```

## Access Control Best Practices

### 1. Least Privilege Principle

- Grant minimum necessary permissions
- Regular role audits and cleanup
- Time-limited permissions where appropriate

### 2. Role Rotation

- Regular rotation of sensitive roles
- Revoke access for inactive members
- Emergency role succession planning

### 3. Monitoring and Alerting

- Real-time monitoring of role usage
- Alerts for unusual access patterns
- Automated anomaly detection

```solidity
contract AccessMonitor {
    mapping(address => uint256) public lastActivity;
    mapping(bytes32 => uint256) public roleUsageCount;

    function recordAccess(address caller, bytes32 role) external {
        lastActivity[caller] = block.timestamp;
        roleUsageCount[role]++;

        emit AccessRecorded(caller, role, block.timestamp);
    }
}
```

## Emergency Procedures

### Emergency Response Levels

#### Level 1: Asset Pause

- Pause specific problematic assets
- Maintain core protocol functionality
- Allow user withdrawals

#### Level 2: Protocol Pause

- Pause all new operations
- Allow emergency withdrawals only
- Activate recovery procedures

#### Level 3: Full Emergency

- Complete protocol lockdown
- Emergency asset recovery
- Manual intervention required

### Emergency Roles Activation

```solidity
function activateEmergency(uint8 level) external {
    require(hasRole(EMERGENCY_ROLE, msg.sender), "Not emergency role");

    emergencyLevel = level;
    emergencyActivatedAt = block.timestamp;

    if (level >= 2) {
        pauseAllOperations();
    }

    if (level >= 3) {
        enableEmergencyWithdrawals();
    }

    emit EmergencyActivated(level, msg.sender, block.timestamp);
}
```

## Role Management Interface

### Granting Roles

```solidity
function grantRole(bytes32 role, address account) external {
    require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role");

    if (role == ADMIN_ROLE) {
        // Additional checks for admin role
        require(isValidAdminCandidate(account), "Invalid admin candidate");
    }

    _grantRole(role, account);
    emit RoleGranted(role, account, msg.sender);
}
```

### Revoking Roles

```solidity
function revokeRole(bytes32 role, address account) external {
    require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role");

    // Prevent removing last admin
    if (role == ADMIN_ROLE) {
        require(getRoleMemberCount(ADMIN_ROLE) > 1, "Cannot remove last admin");
    }

    _revokeRole(role, account);
    emit RoleRevoked(role, account, msg.sender);
}
```

The access management system provides robust security controls while enabling efficient protocol operations and future decentralized governance integration.
