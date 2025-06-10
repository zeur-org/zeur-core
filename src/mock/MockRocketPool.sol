// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MockRocketPool
 * @dev Mock implementation of RocketPool liquid staking protocol
 * Supports:
 * - ETH staking and rETH minting
 * - Node operator system
 * - Minipool creation and management
 * - Reward distribution
 * - rETH/ETH exchange rate
 */
contract MockRocketPool is ERC20, Ownable, ReentrancyGuard {
    // ============ State Variables ============

    /// @notice Total ETH staked in the protocol
    uint256 public totalStaked;

    /// @notice Total rETH supply
    uint256 public rethSupply;

    /// @notice Total rewards earned
    uint256 public totalRewards;

    /// @notice Node operator commission rate (basis points)
    uint256 public nodeOperatorCommission = 1500; // 15%

    /// @notice Protocol fee rate (basis points)
    uint256 public protocolFee = 500; // 5%

    /// @notice Minimum deposit amount
    uint256 public minDeposit = 0.01 ether;

    /// @notice Maximum deposit pool size
    uint256 public maxDepositPoolSize = 5000 ether;

    /// @notice Current deposit pool balance
    uint256 public depositPoolBalance;

    /// @notice RPL token address (mock)
    address public rplToken;

    /// @notice Network token RPL balance
    uint256 public networkRPLBalance;

    // ============ Node Operator System ============

    struct NodeOperator {
        bool registered;
        uint256 rplStake;
        uint256 minipoolCount;
        uint256 effectiveRPLStake;
        bool trusted;
        uint256 registrationTime;
    }

    struct Minipool {
        address nodeOperator;
        uint256 nodeDeposit; // Usually 16 ETH
        uint256 userDeposit; // Usually 16 ETH
        uint256 created;
        MinipoolStatus status;
        uint256 rewards;
    }

    enum MinipoolStatus {
        Prelaunch,
        Staking,
        Withdrawable,
        Dissolved
    }

    // ============ Mappings ============

    /// @notice Node operators registry
    mapping(address => NodeOperator) public nodeOperators;

    /// @notice Minipools by ID
    mapping(uint256 => Minipool) public minipools;

    /// @notice Node operator addresses
    address[] public nodeOperatorAddresses;

    /// @notice Minipool counter
    uint256 public minipoolCount;

    /// @notice User deposit timestamps
    mapping(address => uint256) public userDepositTime;

    // ============ Events ============

    event Deposited(
        address indexed user,
        uint256 ethAmount,
        uint256 rethAmount
    );
    event Burned(address indexed user, uint256 rethAmount, uint256 ethAmount);
    event NodeOperatorRegistered(address indexed nodeOperator);
    event MinipoolCreated(
        uint256 indexed minipoolId,
        address indexed nodeOperator
    );
    event MinipoolStatusChanged(
        uint256 indexed minipoolId,
        MinipoolStatus status
    );
    event RewardsDistributed(uint256 amount);
    event RPLStaked(address indexed nodeOperator, uint256 amount);

    // ============ Constructor ============

    constructor() ERC20("Rocket Pool ETH", "rETH") Ownable(msg.sender) {
        // Initialize with 1:1 ratio
        rethSupply = 0;
    }

    // ============ Core Staking Functions ============

    /**
     * @notice Deposit ETH and receive rETH tokens
     */
    function deposit() external payable nonReentrant {
        require(msg.value >= minDeposit, "Below minimum deposit");
        require(
            depositPoolBalance + msg.value <= maxDepositPoolSize,
            "Deposit pool full"
        );

        uint256 ethAmount = msg.value;
        uint256 rethAmount = calcRETHMinted(ethAmount);

        depositPoolBalance += ethAmount;
        totalStaked += ethAmount;
        userDepositTime[msg.sender] = block.timestamp;

        _mint(msg.sender, rethAmount);
        rethSupply += rethAmount;

        emit Deposited(msg.sender, ethAmount, rethAmount);

        // Try to create minipool if conditions are met
        _tryCreateMinipool();
    }

    /**
     * @notice Burn rETH tokens and receive ETH
     * @param rethAmount Amount of rETH to burn
     */
    function burn(uint256 rethAmount) external nonReentrant {
        require(rethAmount > 0, "Invalid amount");
        require(
            balanceOf(msg.sender) >= rethAmount,
            "Insufficient rETH balance"
        );

        uint256 ethAmount = calcETHReturned(rethAmount);
        require(
            address(this).balance >= ethAmount,
            "Insufficient contract balance"
        );

        _burn(msg.sender, rethAmount);
        rethSupply -= rethAmount;
        totalStaked -= ethAmount;

        payable(msg.sender).transfer(ethAmount);

        emit Burned(msg.sender, rethAmount, ethAmount);
    }

    // ============ Exchange Rate Functions ============

    /**
     * @notice Calculate rETH amount for given ETH deposit
     * @param ethAmount Amount of ETH to deposit
     * @return Amount of rETH that would be minted
     */
    function calcRETHMinted(uint256 ethAmount) public view returns (uint256) {
        if (rethSupply == 0) {
            return ethAmount; // 1:1 initially
        }
        uint256 totalETHValue = totalStaked + totalRewards;
        return (ethAmount * rethSupply) / totalETHValue;
    }

    /**
     * @notice Calculate ETH amount for given rETH burn
     * @param rethAmount Amount of rETH to burn
     * @return Amount of ETH that would be returned
     */
    function calcETHReturned(uint256 rethAmount) public view returns (uint256) {
        if (rethSupply == 0) {
            return 0;
        }
        uint256 totalETHValue = totalStaked + totalRewards;
        return (rethAmount * totalETHValue) / rethSupply;
    }

    /**
     * @notice Get current rETH exchange rate
     * @return Exchange rate (ETH per rETH) with 18 decimals
     */
    function getExchangeRate() external view returns (uint256) {
        if (rethSupply == 0) {
            return 1 ether; // 1:1 initially
        }
        uint256 totalETHValue = totalStaked + totalRewards;
        return (totalETHValue * 1 ether) / rethSupply;
    }

    // ============ Node Operator Functions ============

    /**
     * @notice Register as a node operator
     * @param rplStakeAmount Amount of RPL to stake
     */
    function registerNodeOperator(uint256 rplStakeAmount) external {
        require(!nodeOperators[msg.sender].registered, "Already registered");
        require(rplStakeAmount >= getMinRPLStake(), "Insufficient RPL stake");

        nodeOperators[msg.sender] = NodeOperator({
            registered: true,
            rplStake: rplStakeAmount,
            minipoolCount: 0,
            effectiveRPLStake: rplStakeAmount,
            trusted: false,
            registrationTime: block.timestamp
        });

        nodeOperatorAddresses.push(msg.sender);
        networkRPLBalance += rplStakeAmount;

        emit NodeOperatorRegistered(msg.sender);
    }

    /**
     * @notice Create a minipool (node operator only)
     */
    function createMinipool() external payable {
        require(
            nodeOperators[msg.sender].registered,
            "Not registered node operator"
        );
        require(msg.value >= 16 ether, "Insufficient node deposit");
        require(depositPoolBalance >= 16 ether, "Insufficient user deposits");

        uint256 minipoolId = minipoolCount++;

        minipools[minipoolId] = Minipool({
            nodeOperator: msg.sender,
            nodeDeposit: msg.value,
            userDeposit: 16 ether,
            created: block.timestamp,
            status: MinipoolStatus.Prelaunch,
            rewards: 0
        });

        nodeOperators[msg.sender].minipoolCount++;
        depositPoolBalance -= 16 ether;

        emit MinipoolCreated(minipoolId, msg.sender);
    }

    /**
     * @notice Stake additional RPL
     * @param amount Amount of RPL to stake
     */
    function stakeRPL(uint256 amount) external {
        require(nodeOperators[msg.sender].registered, "Not registered");

        nodeOperators[msg.sender].rplStake += amount;
        nodeOperators[msg.sender].effectiveRPLStake += amount;
        networkRPLBalance += amount;

        emit RPLStaked(msg.sender, amount);
    }

    // ============ Minipool Management ============

    /**
     * @notice Update minipool status
     * @param minipoolId Minipool ID
     * @param newStatus New status
     */
    function updateMinipoolStatus(
        uint256 minipoolId,
        MinipoolStatus newStatus
    ) external onlyOwner {
        require(minipoolId < minipoolCount, "Invalid minipool ID");

        minipools[minipoolId].status = newStatus;
        emit MinipoolStatusChanged(minipoolId, newStatus);
    }

    /**
     * @notice Distribute rewards to a minipool
     * @param minipoolId Minipool ID
     * @param rewardAmount Reward amount
     */
    function distributeMinipoolRewards(
        uint256 minipoolId,
        uint256 rewardAmount
    ) external onlyOwner {
        require(minipoolId < minipoolCount, "Invalid minipool ID");

        Minipool storage minipool = minipools[minipoolId];
        minipool.rewards += rewardAmount;

        // Calculate commission
        uint256 nodeOperatorReward = (rewardAmount * nodeOperatorCommission) /
            10000;
        uint256 protocolFeeAmount = (rewardAmount * protocolFee) / 10000;
        uint256 userReward = rewardAmount -
            nodeOperatorReward -
            protocolFeeAmount;

        totalRewards += userReward;

        emit RewardsDistributed(rewardAmount);
    }

    // ============ Internal Functions ============

    /**
     * @notice Try to create minipool automatically
     */
    function _tryCreateMinipool() internal {
        if (
            depositPoolBalance >= 16 ether && nodeOperatorAddresses.length > 0
        ) {
            // Simple round-robin selection for demo
            address selectedOperator = nodeOperatorAddresses[
                block.timestamp % nodeOperatorAddresses.length
            ];

            if (nodeOperators[selectedOperator].registered) {
                // This would trigger minipool creation in real implementation
                // For mock, we just emit an event
            }
        }
    }

    // ============ View Functions ============

    /**
     * @notice Get minimum RPL stake required
     * @return Minimum RPL stake amount
     */
    function getMinRPLStake() public pure returns (uint256) {
        return 1.6 ether; // Mock: 1.6 RPL minimum
    }

    /**
     * @notice Get maximum RPL stake allowed
     * @return Maximum RPL stake amount
     */
    function getMaxRPLStake() public pure returns (uint256) {
        return 150 ether; // Mock: 150 RPL maximum per minipool
    }

    /**
     * @notice Get node operator details
     * @param nodeOperator Address of node operator
     * @return Node operator struct
     */
    function getNodeOperator(
        address nodeOperator
    ) external view returns (NodeOperator memory) {
        return nodeOperators[nodeOperator];
    }

    /**
     * @notice Get minipool details
     * @param minipoolId Minipool ID
     * @return Minipool struct
     */
    function getMinipool(
        uint256 minipoolId
    ) external view returns (Minipool memory) {
        require(minipoolId < minipoolCount, "Invalid minipool ID");
        return minipools[minipoolId];
    }

    /**
     * @notice Get total value locked
     * @return Total ETH value in protocol
     */
    function getTVL() external view returns (uint256) {
        return totalStaked + totalRewards;
    }

    /**
     * @notice Get deposit pool utilization
     * @return Current utilization percentage (basis points)
     */
    function getDepositPoolUtilization() external view returns (uint256) {
        if (maxDepositPoolSize == 0) return 0;
        return (depositPoolBalance * 10000) / maxDepositPoolSize;
    }

    // ============ Admin Functions ============

    /**
     * @notice Set node operator commission rate
     * @param newCommission New commission rate in basis points
     */
    function setNodeOperatorCommission(
        uint256 newCommission
    ) external onlyOwner {
        require(newCommission <= 2000, "Commission too high"); // Max 20%
        nodeOperatorCommission = newCommission;
    }

    /**
     * @notice Set protocol fee rate
     * @param newFee New fee rate in basis points
     */
    function setProtocolFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Fee too high"); // Max 10%
        protocolFee = newFee;
    }

    /**
     * @notice Set trusted node operator status
     * @param nodeOperator Node operator address
     * @param trusted Whether the operator is trusted
     */
    function setTrustedNodeOperator(
        address nodeOperator,
        bool trusted
    ) external onlyOwner {
        require(nodeOperators[nodeOperator].registered, "Not registered");
        nodeOperators[nodeOperator].trusted = trusted;
    }

    /**
     * @notice Emergency withdraw (owner only)
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner()).transfer(amount);
    }

    // ============ Receive Function ============

    /**
     * @notice Receive ETH deposits
     */
    receive() external payable {
        // Allow direct ETH deposits for rewards/liquidity
    }
}
