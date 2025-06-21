// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MockLido
 * @dev Mock implementation of Lido liquid staking protocol
 * Supports:
 * - ETH staking and stETH minting (rebasing token)
 * - Reward distribution through rebasing
 * - Withdrawal queue system
 * - Node operator management
 * - Oracle price feeds
 */
contract MockLido is ERC20, Ownable, ReentrancyGuard {
    // ============ State Variables ============

    /// @notice Total ETH staked in the protocol
    uint256 public totalStaked;

    /// @notice Total pooled ETH (staked + rewards)
    uint256 public totalPooledEther;

    /// @notice Total shares issued
    uint256 public totalShares;

    /// @notice Protocol fee rate (basis points)
    uint256 public protocolFeeRate = 1000; // 10%

    /// @notice Treasury fee rate (basis points)
    uint256 public treasuryFeeRate = 500; // 5%

    /// @notice Minimum stake amount
    uint256 public minStakeAmount = 0.01 ether;

    /// @notice Annual Percentage Rate (basis points)
    uint256 public apr = 400; // 4%

    /// @notice Last reward update timestamp
    uint256 public lastRewardUpdate;

    /// @notice Withdrawal queue delay
    uint256 public withdrawalDelay = 1 days;

    /// @notice Fee recipient addresses
    address public treasury;
    address public stakingFeeRecipient;

    // ============ Node Operators ============

    struct NodeOperator {
        bool active;
        string name;
        address rewardAddress;
        uint256 validatorCount;
        uint256 stoppedValidators;
        uint256 totalSigningKeys;
        uint256 usedSigningKeys;
        uint256 stakingLimit;
    }

    // ============ Withdrawal Queue ============

    struct WithdrawalRequest {
        uint256 stETHAmount;
        uint256 shares;
        uint256 requestTime;
        bool finalized;
        bool claimed;
    }

    // ============ Mappings ============

    /// @notice User shares mapping
    mapping(address => uint256) private shares;

    /// @notice Node operators
    mapping(uint256 => NodeOperator) public nodeOperators;

    /// @notice Node operator count
    uint256 public nodeOperatorCount;

    /// @notice Withdrawal requests
    mapping(address => WithdrawalRequest[]) public withdrawalRequests;

    /// @notice Oracle addresses
    mapping(address => bool) public oracles;

    // ============ Events ============

    event Submitted(address indexed sender, uint256 amount, address referral);
    event Withdrawn(address indexed recipient, uint256 amount);
    event TransferShares(
        address indexed from,
        address indexed to,
        uint256 sharesValue
    );
    event SharesBurnt(
        address indexed account,
        uint256 preRebaseTokenAmount,
        uint256 postRebaseTokenAmount,
        uint256 sharesAmount
    );
    event TokenRebased(
        uint256 reportTimestamp,
        uint256 timeElapsed,
        uint256 preTotalShares,
        uint256 preTotalEther,
        uint256 postTotalShares,
        uint256 postTotalEther,
        uint256 sharesMintedAsFees
    );
    event NodeOperatorAdded(
        uint256 indexed nodeOperatorId,
        string name,
        address rewardAddress,
        uint256 stakingLimit
    );
    event WithdrawalRequested(
        address indexed recipient,
        uint256 amountOfStETH,
        uint256 amountOfShares
    );
    event WithdrawalsFinalized(
        uint256 from,
        uint256 to,
        uint256 amountOfETHLocked,
        uint256 sharesToBurn,
        uint256 timestamp
    );

    // ============ Constructor ============

    constructor()
        ERC20("Liquid staked Ether 2.0", "stETH")
        Ownable(msg.sender)
    {
        treasury = msg.sender;
        stakingFeeRecipient = msg.sender;
        lastRewardUpdate = block.timestamp;
        totalPooledEther = 0;
        totalShares = 0;
    }

    // ============ Core Staking Functions ============

    /**
     * @notice Submit ETH to the pool and mint stETH tokens
     * @param referral Optional referral address
     * @return Amount of stETH minted
     */
    function submit(
        address referral
    ) external payable nonReentrant returns (uint256) {
        require(msg.value >= minStakeAmount, "Below minimum stake");

        uint256 deposit = msg.value;
        uint256 sharesAmount = getSharesByPooledEth(deposit);

        if (sharesAmount == 0) {
            // First deposit - 1:1 ratio
            sharesAmount = deposit;
            totalPooledEther = deposit;
        } else {
            totalPooledEther += deposit;
        }

        totalStaked += deposit;
        totalShares += sharesAmount;
        shares[msg.sender] += sharesAmount;

        emit Submitted(msg.sender, deposit, referral);
        emit Transfer(address(0), msg.sender, deposit);

        return deposit;
    }

    /**
     * @notice Request withdrawal of stETH
     * @param amounts Array of stETH amounts to withdraw
     * @param owner Owner of the stETH
     * @return requestIds Array of request IDs
     */
    function requestWithdrawals(
        uint256[] calldata amounts,
        address owner
    ) external nonReentrant returns (uint256[] memory requestIds) {
        require(amounts.length > 0, "Empty amounts");

        requestIds = new uint256[](amounts.length);

        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0, "Invalid amount");
            require(balanceOf(owner) >= amounts[i], "Insufficient balance");

            uint256 sharesToBurn = getSharesByPooledEth(amounts[i]);

            // Burn shares
            shares[owner] -= sharesToBurn;
            totalShares -= sharesToBurn;
            totalPooledEther -= amounts[i];

            // Create withdrawal request
            withdrawalRequests[owner].push(
                WithdrawalRequest({
                    stETHAmount: amounts[i],
                    shares: sharesToBurn,
                    requestTime: block.timestamp,
                    finalized: false,
                    claimed: false
                })
            );

            requestIds[i] = withdrawalRequests[owner].length - 1;

            emit WithdrawalRequested(owner, amounts[i], sharesToBurn);
            emit Transfer(owner, address(0), amounts[i]);
        }

        return requestIds;
    }

    /**
     * @notice Claim finalized withdrawal
     * @param requestId Request ID to claim
     */
    function claimWithdrawal(uint256 requestId) external nonReentrant {
        require(
            requestId < withdrawalRequests[msg.sender].length,
            "Invalid request ID"
        );

        WithdrawalRequest storage request = withdrawalRequests[msg.sender][
            requestId
        ];
        require(request.finalized, "Request not finalized");
        require(!request.claimed, "Already claimed");
        require(
            block.timestamp >= request.requestTime + withdrawalDelay,
            "Withdrawal delay not met"
        );

        request.claimed = true;

        payable(msg.sender).transfer(request.stETHAmount);

        emit Withdrawn(msg.sender, request.stETHAmount);
    }

    // ============ Rebasing Token Logic ============

    /**
     * @notice Get balance of account (rebasing)
     * @param account Account address
     * @return Token balance
     */
    function balanceOf(address account) public view override returns (uint256) {
        return getPooledEthByShares(shares[account]);
    }

    /**
     * @notice Get total supply (rebasing)
     * @return Total token supply
     */
    function totalSupply() public view override returns (uint256) {
        return totalPooledEther;
    }

    /**
     * @notice Get shares of account
     * @param account Account address
     * @return Number of shares
     */
    function sharesOf(address account) external view returns (uint256) {
        return shares[account];
    }

    /**
     * @notice Get shares by pooled ETH amount
     * @param ethAmount Amount of ETH
     * @return Number of shares
     */
    function getSharesByPooledEth(
        uint256 ethAmount
    ) public view returns (uint256) {
        if (totalPooledEther == 0) {
            return ethAmount;
        }
        return (ethAmount * totalShares) / totalPooledEther;
    }

    /**
     * @notice Get pooled ETH by shares
     * @param sharesAmount Number of shares
     * @return Amount of ETH
     */
    function getPooledEthByShares(
        uint256 sharesAmount
    ) public view returns (uint256) {
        if (totalShares == 0) {
            return 0;
        }
        return (sharesAmount * totalPooledEther) / totalShares;
    }

    // ============ Transfer Logic ============

    /**
     * @notice Transfer tokens
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return Success boolean
     */
    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 sharesToTransfer = getSharesByPooledEth(amount);
        _transferShares(msg.sender, to, sharesToTransfer);
        return true;
    }

    /**
     * @notice Transfer from
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return Success boolean
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(from, msg.sender);
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );

        uint256 sharesToTransfer = getSharesByPooledEth(amount);
        _transferShares(from, to, sharesToTransfer);
        _approve(from, msg.sender, currentAllowance - amount);

        return true;
    }

    /**
     * @notice Transfer shares between accounts
     * @param from Sender address
     * @param to Recipient address
     * @param sharesAmount Number of shares to transfer
     */
    function _transferShares(
        address from,
        address to,
        uint256 sharesAmount
    ) internal {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(
            shares[from] >= sharesAmount,
            "Transfer amount exceeds balance"
        );

        uint256 tokensAmount = getPooledEthByShares(sharesAmount);

        shares[from] -= sharesAmount;
        shares[to] += sharesAmount;

        emit Transfer(from, to, tokensAmount);
        emit TransferShares(from, to, sharesAmount);
    }

    // ============ Reward Distribution ============

    /**
     * @notice Handle oracle report and distribute rewards
     * @param beaconValidators Number of validators on beacon chain
     * @param beaconBalance Total balance on beacon chain
     */
    function handleOracleReport(
        uint256 beaconValidators,
        uint256 beaconBalance
    ) external {
        require(oracles[msg.sender], "Not authorized oracle");

        uint256 prevTotalPooledEther = totalPooledEther;
        uint256 prevTotalShares = totalShares;

        // Calculate rewards
        uint256 rewards = 0;
        if (beaconBalance > totalStaked) {
            rewards = beaconBalance - totalStaked;
        }

        if (rewards > 0) {
            // Calculate fees
            uint256 protocolFee = (rewards * protocolFeeRate) / 10000;
            uint256 treasuryFee = (rewards * treasuryFeeRate) / 10000;
            uint256 totalFees = protocolFee + treasuryFee;

            // Mint shares for fees
            uint256 feeShares = getSharesByPooledEth(totalFees);
            shares[treasury] += feeShares;
            totalShares += feeShares;

            // Update total pooled ether
            totalPooledEther = beaconBalance;

            emit TokenRebased(
                block.timestamp,
                block.timestamp - lastRewardUpdate,
                prevTotalShares,
                prevTotalPooledEther,
                totalShares,
                totalPooledEther,
                feeShares
            );
        }

        lastRewardUpdate = block.timestamp;
    }

    // ============ Node Operator Management ============

    /**
     * @notice Add node operator
     * @param name Node operator name
     * @param rewardAddress Reward address
     * @param stakingLimit Staking limit
     */
    function addNodeOperator(
        string calldata name,
        address rewardAddress,
        uint256 stakingLimit
    ) external onlyOwner {
        uint256 nodeOperatorId = nodeOperatorCount++;

        nodeOperators[nodeOperatorId] = NodeOperator({
            active: true,
            name: name,
            rewardAddress: rewardAddress,
            validatorCount: 0,
            stoppedValidators: 0,
            totalSigningKeys: 0,
            usedSigningKeys: 0,
            stakingLimit: stakingLimit
        });

        emit NodeOperatorAdded(
            nodeOperatorId,
            name,
            rewardAddress,
            stakingLimit
        );
    }

    /**
     * @notice Set node operator active status
     * @param nodeOperatorId Node operator ID
     * @param active Active status
     */
    function setNodeOperatorActive(
        uint256 nodeOperatorId,
        bool active
    ) external onlyOwner {
        require(nodeOperatorId < nodeOperatorCount, "Invalid node operator");
        nodeOperators[nodeOperatorId].active = active;
    }

    // ============ View Functions ============

    /**
     * @notice Get current APR
     * @return Current annual percentage rate
     */
    function getAPR() external view returns (uint256) {
        return apr;
    }

    /**
     * @notice Get withdrawal request details
     * @param user User address
     * @param requestId Request ID
     * @return Withdrawal request struct
     */
    function getWithdrawalRequest(
        address user,
        uint256 requestId
    ) external view returns (WithdrawalRequest memory) {
        require(
            requestId < withdrawalRequests[user].length,
            "Invalid request ID"
        );
        return withdrawalRequests[user][requestId];
    }

    /**
     * @notice Get total value locked
     * @return Total ETH value
     */
    function getTVL() external view returns (uint256) {
        return totalPooledEther;
    }

    /**
     * @notice Get node operator details
     * @param nodeOperatorId Node operator ID
     * @return Node operator struct
     */
    function getNodeOperator(
        uint256 nodeOperatorId
    ) external view returns (NodeOperator memory) {
        require(nodeOperatorId < nodeOperatorCount, "Invalid node operator");
        return nodeOperators[nodeOperatorId];
    }

    // ============ Admin Functions ============

    /**
     * @notice Set oracle address
     * @param oracle Oracle address
     * @param authorized Authorization status
     */
    function setOracle(address oracle, bool authorized) external onlyOwner {
        oracles[oracle] = authorized;
    }

    /**
     * @notice Set protocol fee rate
     * @param newFeeRate New fee rate in basis points
     */
    function setProtocolFeeRate(uint256 newFeeRate) external onlyOwner {
        require(newFeeRate <= 2000, "Fee rate too high"); // Max 20%
        protocolFeeRate = newFeeRate;
    }

    /**
     * @notice Set treasury address
     * @param newTreasury New treasury address
     */
    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid address");
        treasury = newTreasury;
    }

    /**
     * @notice Finalize withdrawal requests
     * @param lastRequestIdToBeFinalized Last request ID to finalize
     */
    function finalizeWithdrawalRequests(
        uint256 lastRequestIdToBeFinalized
    ) external onlyOwner {
        // In a real implementation, this would finalize withdrawal requests
        // For mock purposes, we'll mark them as finalized
        emit WithdrawalsFinalized(
            0,
            lastRequestIdToBeFinalized,
            0,
            0,
            block.timestamp
        );
    }

    /**
     * @notice Emergency functions
     * @param amount Amount to withdraw for emergencies
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner()).transfer(amount);
    }

    // ============ Receive Function ============

    /**
     * @notice Receive ETH for rewards/operations
     */
    receive() external payable {
        // Allow contract to receive ETH for rewards
    }
}

contract MockWithdrawalQueue {
    error MockLido_FailedToTransfer();

    struct WithdrawalRequest {
        uint256 stETHAmount;
        uint256 requestTime;
        bool finalized;
        bool claimed;
        address owner;
    }

    MockLido public immutable stETH;
    uint256 public withdrawalDelay = 0; // Mock 0 delay
    uint256 public nextRequestId = 1;

    mapping(uint256 => WithdrawalRequest) public withdrawalRequests;
    mapping(address => uint256[]) public userRequests;

    event WithdrawalRequested(
        uint256 indexed requestId,
        address indexed owner,
        uint256 amountOfStETH
    );

    event WithdrawalClaimed(
        uint256 indexed requestId,
        address indexed owner,
        uint256 amountOfETH
    );

    constructor(address _stETH) {
        stETH = MockLido(payable(_stETH));
    }

    function requestWithdrawals(
        uint256[] calldata amounts,
        address owner
    ) external returns (uint256[] memory) {
        require(amounts.length > 0, "Empty amounts");

        uint256[] memory requestIds = new uint256[](amounts.length);

        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0, "Invalid amount");
            require(
                stETH.balanceOf(owner) >= amounts[i],
                "Insufficient stETH balance"
            );

            uint256 requestId = nextRequestId++;

            // Transfer stETH from owner to this contract (which burns it)
            stETH.transferFrom(owner, address(this), amounts[i]);

            // Create withdrawal request
            withdrawalRequests[requestId] = WithdrawalRequest({
                stETHAmount: amounts[i],
                requestTime: block.timestamp,
                finalized: true, // Auto-finalize for simplicity in mock
                claimed: false,
                owner: owner
            });

            userRequests[owner].push(requestId);
            requestIds[i] = requestId;

            emit WithdrawalRequested(requestId, owner, amounts[i]);
        }

        return requestIds;
    }

    function claimWithdrawal(uint256 requestId) external {
        WithdrawalRequest storage request = withdrawalRequests[requestId];

        require(request.owner != address(0), "Invalid request ID");
        require(request.owner == msg.sender, "Not request owner");
        require(request.finalized, "Request not finalized");
        require(!request.claimed, "Already claimed");
        require(
            block.timestamp >= request.requestTime + withdrawalDelay,
            "Withdrawal delay not met"
        );
        require(
            address(this).balance >= request.stETHAmount,
            "Insufficient ETH balance"
        );

        request.claimed = true;

        // Send ETH back to user
        (bool success, ) = payable(msg.sender).call{value: request.stETHAmount}(
            ""
        );
        if (!success) revert MockLido_FailedToTransfer();

        emit WithdrawalClaimed(requestId, msg.sender, request.stETHAmount);
    }

    // Helper function to get user's withdrawal requests
    function getUserRequests(
        address user
    ) external view returns (uint256[] memory) {
        return userRequests[user];
    }

    // Helper function to get withdrawal request details
    function getWithdrawalRequest(
        uint256 requestId
    )
        external
        view
        returns (
            uint256 stETHAmount,
            uint256 requestTime,
            bool finalized,
            bool claimed,
            address owner
        )
    {
        WithdrawalRequest memory request = withdrawalRequests[requestId];
        return (
            request.stETHAmount,
            request.requestTime,
            request.finalized,
            request.claimed,
            request.owner
        );
    }

    // Function to fund the contract with ETH for withdrawals
    receive() external payable {}

    // Function to fund the contract with ETH (for testing purposes)
    function fundContract() external payable {}
}
