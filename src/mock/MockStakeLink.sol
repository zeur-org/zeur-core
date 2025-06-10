// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MockStakeLink
 * @dev Mock implementation of Chainlink staking protocol
 * Supports:
 * - LINK token staking and stLINK minting
 * - Delegation to node operators
 * - Reward distribution
 * - Slashing mechanisms
 * - Migration and unstaking
 */
contract MockStakeLink is ERC20, Ownable, ReentrancyGuard {
    // ============ State Variables ============

    /// @notice LINK token contract
    IERC20 public immutable linkToken;

    /// @notice Total LINK staked in the protocol
    uint256 public totalStaked;

    /// @notice Total rewards distributed
    uint256 public totalRewards;

    /// @notice Protocol fee rate (basis points)
    uint256 public protocolFeeRate = 500; // 5%

    /// @notice Minimum stake amount
    uint256 public minStakeAmount = 100 * 1e18; // 100 LINK

    /// @notice Maximum stake amount per user
    uint256 public maxStakeAmount = 50000 * 1e18; // 50,000 LINK

    /// @notice Annual Percentage Rate (basis points)
    uint256 public apr = 800; // 8%

    /// @notice Last reward update timestamp
    uint256 public lastRewardUpdate;

    /// @notice Unstaking delay period
    uint256 public unstakingDelay = 21 days;

    /// @notice Slashing enabled flag
    bool public slashingEnabled = true;

    /// @notice Maximum slashing percentage (basis points)
    uint256 public maxSlashingRate = 1000; // 10%

    // ============ Node Operators ============

    struct NodeOperator {
        bool registered;
        bool active;
        string name;
        address operatorAddress;
        uint256 totalStaked;
        uint256 capacity;
        uint256 commission; // basis points
        uint256 slashingCount;
        uint256 lastSlashingTime;
        uint256 reputation; // basis points (10000 = 100%)
    }

    // ============ Staking ============

    struct StakePosition {
        uint256 amount;
        uint256 timestamp;
        address delegatedOperator;
        uint256 rewards;
        uint256 lastRewardUpdate;
    }

    struct UnstakeRequest {
        uint256 amount;
        uint256 requestTime;
        bool processed;
    }

    // ============ Mappings ============

    /// @notice Node operators registry
    mapping(address => NodeOperator) public nodeOperators;

    /// @notice Node operator addresses list
    address[] public nodeOperatorAddresses;

    /// @notice User stake positions
    mapping(address => StakePosition) public stakePositions;

    /// @notice User unstake requests
    mapping(address => UnstakeRequest[]) public unstakeRequests;

    /// @notice Operator delegated stakes
    mapping(address => uint256) public operatorDelegatedStakes;

    /// @notice User to operator delegation mapping
    mapping(address => address) public userDelegations;

    // ============ Events ============

    event Staked(
        address indexed user,
        uint256 linkAmount,
        uint256 stLinkAmount,
        address delegatedOperator
    );
    event Unstaked(
        address indexed user,
        uint256 stLinkAmount,
        uint256 linkAmount
    );
    event UnstakeRequested(
        address indexed user,
        uint256 amount,
        uint256 requestId
    );
    event UnstakeProcessed(
        address indexed user,
        uint256 amount,
        uint256 requestId
    );
    event RewardsDistributed(uint256 totalRewards, uint256 timestamp);
    event RewardsClaimed(address indexed user, uint256 amount);
    event NodeOperatorRegistered(
        address indexed operator,
        string name,
        uint256 capacity
    );
    event NodeOperatorSlashed(
        address indexed operator,
        uint256 slashAmount,
        string reason
    );
    event DelegationChanged(
        address indexed user,
        address indexed oldOperator,
        address indexed newOperator
    );
    event OperatorCommissionUpdated(
        address indexed operator,
        uint256 newCommission
    );

    // ============ Constructor ============

    constructor(
        address _linkToken
    ) ERC20("Staked LINK", "stLINK") Ownable(msg.sender) {
        require(_linkToken != address(0), "Invalid LINK token address");
        linkToken = IERC20(_linkToken);
        lastRewardUpdate = block.timestamp;
    }

    // ============ Core Staking Functions ============

    /**
     * @notice Stake LINK tokens and receive stLINK
     * @param amount Amount of LINK to stake
     * @param delegateOperator Node operator to delegate to
     */
    function stake(
        uint256 amount,
        address delegateOperator
    ) external nonReentrant {
        require(amount >= minStakeAmount, "Below minimum stake amount");
        require(amount <= maxStakeAmount, "Above maximum stake amount");
        require(nodeOperators[delegateOperator].registered, "Invalid operator");
        require(nodeOperators[delegateOperator].active, "Operator not active");

        _updateRewards(msg.sender);

        // Transfer LINK from user
        require(
            linkToken.transferFrom(msg.sender, address(this), amount),
            "LINK transfer failed"
        );

        // Calculate stLINK amount (1:1 initially, then based on exchange rate)
        uint256 stLinkAmount = _calculateStLinkAmount(amount);

        // Update user stake position
        StakePosition storage position = stakePositions[msg.sender];
        position.amount += amount;
        position.timestamp = block.timestamp;
        position.delegatedOperator = delegateOperator;
        position.lastRewardUpdate = block.timestamp;

        // Update operator delegation
        if (userDelegations[msg.sender] != delegateOperator) {
            address oldOperator = userDelegations[msg.sender];
            if (oldOperator != address(0)) {
                operatorDelegatedStakes[oldOperator] -= position.amount;
            }
            operatorDelegatedStakes[delegateOperator] += amount;
            userDelegations[msg.sender] = delegateOperator;
            emit DelegationChanged(msg.sender, oldOperator, delegateOperator);
        } else {
            operatorDelegatedStakes[delegateOperator] += amount;
        }

        totalStaked += amount;

        // Mint stLINK tokens
        _mint(msg.sender, stLinkAmount);

        emit Staked(msg.sender, amount, stLinkAmount, delegateOperator);
    }

    /**
     * @notice Request unstaking of stLINK tokens
     * @param stLinkAmount Amount of stLINK to unstake
     */
    function requestUnstake(uint256 stLinkAmount) external nonReentrant {
        require(stLinkAmount > 0, "Invalid amount");
        require(
            balanceOf(msg.sender) >= stLinkAmount,
            "Insufficient stLINK balance"
        );

        _updateRewards(msg.sender);

        uint256 linkAmount = _calculateLinkAmount(stLinkAmount);

        // Burn stLINK tokens
        _burn(msg.sender, stLinkAmount);

        // Update stake position
        StakePosition storage position = stakePositions[msg.sender];
        require(position.amount >= linkAmount, "Insufficient staked amount");

        position.amount -= linkAmount;

        // Update operator delegation
        address operator = position.delegatedOperator;
        if (operator != address(0)) {
            operatorDelegatedStakes[operator] -= linkAmount;
        }

        totalStaked -= linkAmount;

        // Create unstake request
        unstakeRequests[msg.sender].push(
            UnstakeRequest({
                amount: linkAmount,
                requestTime: block.timestamp,
                processed: false
            })
        );

        uint256 requestId = unstakeRequests[msg.sender].length - 1;

        emit UnstakeRequested(msg.sender, linkAmount, requestId);
    }

    /**
     * @notice Process unstake request after delay period
     * @param requestId Index of unstake request
     */
    function processUnstake(uint256 requestId) external nonReentrant {
        require(
            requestId < unstakeRequests[msg.sender].length,
            "Invalid request ID"
        );

        UnstakeRequest storage request = unstakeRequests[msg.sender][requestId];
        require(!request.processed, "Request already processed");
        require(
            block.timestamp >= request.requestTime + unstakingDelay,
            "Unstaking delay not met"
        );

        request.processed = true;

        // Transfer LINK back to user
        require(
            linkToken.transfer(msg.sender, request.amount),
            "LINK transfer failed"
        );

        emit UnstakeProcessed(msg.sender, request.amount, requestId);
    }

    // ============ Reward Functions ============

    /**
     * @notice Update rewards for a user
     * @param user User address
     */
    function _updateRewards(address user) internal {
        StakePosition storage position = stakePositions[user];
        if (position.amount == 0) return;

        uint256 timeElapsed = block.timestamp - position.lastRewardUpdate;
        if (timeElapsed == 0) return;

        // Calculate rewards
        uint256 rewardAmount = (position.amount * apr * timeElapsed) /
            (365 days * 10000);

        if (rewardAmount > 0) {
            // Deduct operator commission
            address operator = position.delegatedOperator;
            uint256 operatorCommission = 0;
            if (operator != address(0)) {
                operatorCommission =
                    (rewardAmount * nodeOperators[operator].commission) /
                    10000;
                rewardAmount -= operatorCommission;
            }

            position.rewards += rewardAmount;
            totalRewards += rewardAmount;
        }

        position.lastRewardUpdate = block.timestamp;
    }

    /**
     * @notice Claim accumulated rewards
     */
    function claimRewards() external nonReentrant {
        _updateRewards(msg.sender);

        StakePosition storage position = stakePositions[msg.sender];
        uint256 rewardAmount = position.rewards;
        require(rewardAmount > 0, "No rewards to claim");

        position.rewards = 0;

        // Mint stLINK as rewards (auto-compounding)
        _mint(msg.sender, rewardAmount);

        emit RewardsClaimed(msg.sender, rewardAmount);
    }

    /**
     * @notice Distribute rewards (called by protocol)
     */
    function distributeRewards() external onlyOwner {
        lastRewardUpdate = block.timestamp;
        emit RewardsDistributed(totalRewards, block.timestamp);
    }

    // ============ Node Operator Functions ============

    /**
     * @notice Register as a node operator
     * @param name Operator name
     * @param capacity Staking capacity
     * @param commission Commission rate in basis points
     */
    function registerNodeOperator(
        string calldata name,
        uint256 capacity,
        uint256 commission
    ) external {
        require(!nodeOperators[msg.sender].registered, "Already registered");
        require(commission <= 2000, "Commission too high"); // Max 20%
        require(capacity >= 10000 * 1e18, "Capacity too low"); // Min 10,000 LINK

        nodeOperators[msg.sender] = NodeOperator({
            registered: true,
            active: true,
            name: name,
            operatorAddress: msg.sender,
            totalStaked: 0,
            capacity: capacity,
            commission: commission,
            slashingCount: 0,
            lastSlashingTime: 0,
            reputation: 10000 // Start with 100% reputation
        });

        nodeOperatorAddresses.push(msg.sender);

        emit NodeOperatorRegistered(msg.sender, name, capacity);
    }

    /**
     * @notice Update operator commission
     * @param newCommission New commission rate in basis points
     */
    function updateOperatorCommission(uint256 newCommission) external {
        require(
            nodeOperators[msg.sender].registered,
            "Not registered operator"
        );
        require(newCommission <= 2000, "Commission too high");

        nodeOperators[msg.sender].commission = newCommission;

        emit OperatorCommissionUpdated(msg.sender, newCommission);
    }

    /**
     * @notice Slash a node operator (admin only)
     * @param operator Operator to slash
     * @param slashPercentage Percentage to slash (basis points)
     * @param reason Reason for slashing
     */
    function slashOperator(
        address operator,
        uint256 slashPercentage,
        string calldata reason
    ) external onlyOwner {
        require(slashingEnabled, "Slashing disabled");
        require(nodeOperators[operator].registered, "Operator not registered");
        require(
            slashPercentage <= maxSlashingRate,
            "Slash percentage too high"
        );

        uint256 delegatedAmount = operatorDelegatedStakes[operator];
        uint256 slashAmount = (delegatedAmount * slashPercentage) / 10000;

        if (slashAmount > 0) {
            totalStaked -= slashAmount;
            operatorDelegatedStakes[operator] -= slashAmount;

            // Update operator stats
            nodeOperators[operator].slashingCount++;
            nodeOperators[operator].lastSlashingTime = block.timestamp;

            // Reduce reputation
            uint256 reputationPenalty = slashPercentage / 2; // Half of slash percentage
            if (nodeOperators[operator].reputation > reputationPenalty) {
                nodeOperators[operator].reputation -= reputationPenalty;
            } else {
                nodeOperators[operator].reputation = 0;
            }

            emit NodeOperatorSlashed(operator, slashAmount, reason);
        }
    }

    // ============ Exchange Rate Functions ============

    /**
     * @notice Calculate stLINK amount for given LINK amount
     * @param linkAmount Amount of LINK
     * @return Amount of stLINK
     */
    function _calculateStLinkAmount(
        uint256 linkAmount
    ) internal view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            return linkAmount; // 1:1 initially
        }
        return (linkAmount * totalSupply) / (totalStaked + totalRewards);
    }

    /**
     * @notice Calculate LINK amount for given stLINK amount
     * @param stLinkAmount Amount of stLINK
     * @return Amount of LINK
     */
    function _calculateLinkAmount(
        uint256 stLinkAmount
    ) internal view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            return 0;
        }
        return (stLinkAmount * (totalStaked + totalRewards)) / totalSupply;
    }

    /**
     * @notice Get current exchange rate
     * @return Exchange rate (LINK per stLINK) with 18 decimals
     */
    function getExchangeRate() external view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            return 1e18; // 1:1 initially
        }
        return ((totalStaked + totalRewards) * 1e18) / totalSupply;
    }

    // ============ View Functions ============

    /**
     * @notice Get user's pending rewards
     * @param user User address
     * @return Pending reward amount
     */
    function getPendingRewards(address user) external view returns (uint256) {
        StakePosition memory position = stakePositions[user];
        if (position.amount == 0) return position.rewards;

        uint256 timeElapsed = block.timestamp - position.lastRewardUpdate;
        uint256 newRewards = (position.amount * apr * timeElapsed) /
            (365 days * 10000);

        // Deduct operator commission
        address operator = position.delegatedOperator;
        if (operator != address(0)) {
            uint256 operatorCommission = (newRewards *
                nodeOperators[operator].commission) / 10000;
            newRewards -= operatorCommission;
        }

        return position.rewards + newRewards;
    }

    /**
     * @notice Get user's unstake requests
     * @param user User address
     * @return Array of unstake requests
     */
    function getUserUnstakeRequests(
        address user
    ) external view returns (UnstakeRequest[] memory) {
        return unstakeRequests[user];
    }

    /**
     * @notice Get node operator details
     * @param operator Operator address
     * @return Node operator struct
     */
    function getNodeOperator(
        address operator
    ) external view returns (NodeOperator memory) {
        return nodeOperators[operator];
    }

    /**
     * @notice Get total value locked
     * @return Total LINK value
     */
    function getTVL() external view returns (uint256) {
        return totalStaked + totalRewards;
    }

    /**
     * @notice Check if unstake can be processed
     * @param user User address
     * @param requestId Request ID
     * @return Whether unstake can be processed
     */
    function canProcessUnstake(
        address user,
        uint256 requestId
    ) external view returns (bool) {
        if (requestId >= unstakeRequests[user].length) return false;

        UnstakeRequest memory request = unstakeRequests[user][requestId];
        return
            !request.processed &&
            block.timestamp >= request.requestTime + unstakingDelay;
    }

    // ============ Admin Functions ============

    /**
     * @notice Set protocol parameters
     * @param newAPR New APR in basis points
     * @param newFeeRate New protocol fee rate
     * @param newUnstakingDelay New unstaking delay
     */
    function setProtocolParams(
        uint256 newAPR,
        uint256 newFeeRate,
        uint256 newUnstakingDelay
    ) external onlyOwner {
        require(newAPR <= 2000, "APR too high"); // Max 20%
        require(newFeeRate <= 1000, "Fee rate too high"); // Max 10%
        require(newUnstakingDelay <= 90 days, "Delay too long");

        apr = newAPR;
        protocolFeeRate = newFeeRate;
        unstakingDelay = newUnstakingDelay;
    }

    /**
     * @notice Set operator active status
     * @param operator Operator address
     * @param active Active status
     */
    function setOperatorActive(
        address operator,
        bool active
    ) external onlyOwner {
        require(nodeOperators[operator].registered, "Operator not registered");
        nodeOperators[operator].active = active;
    }

    /**
     * @notice Enable/disable slashing
     * @param enabled Slashing enabled flag
     */
    function setSlashingEnabled(bool enabled) external onlyOwner {
        slashingEnabled = enabled;
    }

    /**
     * @notice Emergency withdraw LINK tokens
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(linkToken.transfer(owner(), amount), "Transfer failed");
    }
}
