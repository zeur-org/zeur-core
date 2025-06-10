// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MockEtherfi
 * @dev Mock implementation of EtherFi liquid staking protocol
 * Supports:
 * - ETH staking and eETH minting
 * - Unstaking with withdrawal queue
 * - Reward accrual simulation
 * - Fee collection
 */
contract MockEtherfi is ERC20, Ownable, ReentrancyGuard {
    // ============ State Variables ============

    /// @notice Total ETH staked in the protocol
    uint256 public totalStaked;

    /// @notice Total rewards accrued
    uint256 public totalRewards;

    /// @notice Protocol fee rate (basis points, 100 = 1%)
    uint256 public protocolFeeRate = 100; // 1%

    /// @notice Minimum stake amount
    uint256 public minStakeAmount = 0.01 ether;

    /// @notice Maximum stake amount per transaction
    uint256 public maxStakeAmount = 1000 ether;

    /// @notice Annual Percentage Rate (basis points, 500 = 5%)
    uint256 public apr = 500; // 5%

    /// @notice Last reward update timestamp
    uint256 public lastRewardUpdate;

    /// @notice Withdrawal delay in seconds (7 days)
    uint256 public withdrawalDelay = 7 days;

    /// @notice Exchange rate precision
    uint256 private constant PRECISION = 1e18;

    // ============ Structs ============

    struct WithdrawalRequest {
        uint256 eethAmount;
        uint256 ethAmount;
        uint256 requestTime;
        bool processed;
    }

    // ============ Mappings ============

    /// @notice User withdrawal requests
    mapping(address => WithdrawalRequest[]) public withdrawalRequests;

    /// @notice User staking timestamps for reward calculation
    mapping(address => uint256) public lastStakeTime;

    // ============ Events ============

    event Staked(address indexed user, uint256 ethAmount, uint256 eethAmount);
    event WithdrawalRequested(
        address indexed user,
        uint256 eethAmount,
        uint256 ethAmount,
        uint256 requestId
    );
    event WithdrawalProcessed(
        address indexed user,
        uint256 ethAmount,
        uint256 requestId
    );
    event RewardsDistributed(uint256 rewardAmount);
    event ProtocolFeeUpdated(uint256 newFeeRate);
    event APRUpdated(uint256 newAPR);

    // ============ Constructor ============

    constructor() ERC20("EtherFi ETH", "eETH") Ownable(msg.sender) {
        lastRewardUpdate = block.timestamp;
    }

    // ============ Core Functions ============

    /**
     * @notice Stake ETH and receive eETH tokens
     * @dev Exchange rate calculated based on total staked ETH and eETH supply
     */
    function stake() external payable nonReentrant {
        require(msg.value >= minStakeAmount, "Below minimum stake amount");
        require(msg.value <= maxStakeAmount, "Above maximum stake amount");

        _updateRewards();

        uint256 ethAmount = msg.value;
        uint256 eethAmount = _calculateEETHAmount(ethAmount);

        totalStaked += ethAmount;
        lastStakeTime[msg.sender] = block.timestamp;

        _mint(msg.sender, eethAmount);

        emit Staked(msg.sender, ethAmount, eethAmount);
    }

    /**
     * @notice Request withdrawal of staked ETH
     * @param eethAmount Amount of eETH to unstake
     */
    function requestWithdrawal(uint256 eethAmount) external nonReentrant {
        require(eethAmount > 0, "Invalid amount");
        require(
            balanceOf(msg.sender) >= eethAmount,
            "Insufficient eETH balance"
        );

        _updateRewards();

        uint256 ethAmount = _calculateETHAmount(eethAmount);

        // Burn eETH tokens
        _burn(msg.sender, eethAmount);

        // Create withdrawal request
        withdrawalRequests[msg.sender].push(
            WithdrawalRequest({
                eethAmount: eethAmount,
                ethAmount: ethAmount,
                requestTime: block.timestamp,
                processed: false
            })
        );

        uint256 requestId = withdrawalRequests[msg.sender].length - 1;

        emit WithdrawalRequested(msg.sender, eethAmount, ethAmount, requestId);
    }

    /**
     * @notice Process withdrawal request after delay period
     * @param requestId Index of withdrawal request
     */
    function processWithdrawal(uint256 requestId) external nonReentrant {
        require(
            requestId < withdrawalRequests[msg.sender].length,
            "Invalid request ID"
        );

        WithdrawalRequest storage request = withdrawalRequests[msg.sender][
            requestId
        ];
        require(!request.processed, "Request already processed");
        require(
            block.timestamp >= request.requestTime + withdrawalDelay,
            "Withdrawal delay not met"
        );
        require(
            address(this).balance >= request.ethAmount,
            "Insufficient contract balance"
        );

        request.processed = true;
        totalStaked -= request.ethAmount;

        // Transfer ETH to user
        payable(msg.sender).transfer(request.ethAmount);

        emit WithdrawalProcessed(msg.sender, request.ethAmount, requestId);
    }

    /**
     * @notice Get exchange rate from ETH to eETH
     * @return Exchange rate with 18 decimal precision
     */
    function getExchangeRate() public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            return PRECISION; // 1:1 initially
        }
        return ((totalStaked + totalRewards) * PRECISION) / totalSupply;
    }

    /**
     * @notice Calculate eETH amount for given ETH amount
     * @param ethAmount Amount of ETH
     * @return Amount of eETH tokens
     */
    function _calculateEETHAmount(
        uint256 ethAmount
    ) internal view returns (uint256) {
        uint256 exchangeRate = getExchangeRate();
        return (ethAmount * PRECISION) / exchangeRate;
    }

    /**
     * @notice Calculate ETH amount for given eETH amount
     * @param eethAmount Amount of eETH
     * @return Amount of ETH
     */
    function _calculateETHAmount(
        uint256 eethAmount
    ) internal view returns (uint256) {
        uint256 exchangeRate = getExchangeRate();
        return (eethAmount * exchangeRate) / PRECISION;
    }

    /**
     * @notice Update rewards based on time elapsed and APR
     */
    function _updateRewards() internal {
        if (totalStaked == 0) {
            lastRewardUpdate = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - lastRewardUpdate;
        if (timeElapsed == 0) return;

        // Calculate rewards: staked * APR * time / (365 days * 10000)
        uint256 rewardAmount = (totalStaked * apr * timeElapsed) /
            (365 days * 10000);

        if (rewardAmount > 0) {
            // Deduct protocol fee
            uint256 protocolFee = (rewardAmount * protocolFeeRate) / 10000;
            uint256 netReward = rewardAmount - protocolFee;

            totalRewards += netReward;
            lastRewardUpdate = block.timestamp;

            emit RewardsDistributed(netReward);
        }
    }

    // ============ View Functions ============

    /**
     * @notice Get user's withdrawal requests
     * @param user Address of the user
     * @return Array of withdrawal requests
     */
    function getUserWithdrawalRequests(
        address user
    ) external view returns (WithdrawalRequest[] memory) {
        return withdrawalRequests[user];
    }

    /**
     * @notice Get pending rewards for the protocol
     * @return Amount of pending rewards
     */
    function getPendingRewards() external view returns (uint256) {
        if (totalStaked == 0) return 0;

        uint256 timeElapsed = block.timestamp - lastRewardUpdate;
        return (totalStaked * apr * timeElapsed) / (365 days * 10000);
    }

    /**
     * @notice Get total value locked (TVL) in ETH
     * @return Total ETH value in the protocol
     */
    function getTVL() external view returns (uint256) {
        return totalStaked + totalRewards;
    }

    /**
     * @notice Check if withdrawal can be processed
     * @param user Address of the user
     * @param requestId Index of withdrawal request
     * @return Whether withdrawal can be processed
     */
    function canProcessWithdrawal(
        address user,
        uint256 requestId
    ) external view returns (bool) {
        if (requestId >= withdrawalRequests[user].length) return false;

        WithdrawalRequest memory request = withdrawalRequests[user][requestId];
        return
            !request.processed &&
            block.timestamp >= request.requestTime + withdrawalDelay &&
            address(this).balance >= request.ethAmount;
    }

    // ============ Admin Functions ============

    /**
     * @notice Update protocol fee rate (only owner)
     * @param newFeeRate New fee rate in basis points
     */
    function setProtocolFeeRate(uint256 newFeeRate) external onlyOwner {
        require(newFeeRate <= 1000, "Fee rate too high"); // Max 10%
        protocolFeeRate = newFeeRate;
        emit ProtocolFeeUpdated(newFeeRate);
    }

    /**
     * @notice Update APR (only owner)
     * @param newAPR New APR in basis points
     */
    function setAPR(uint256 newAPR) external onlyOwner {
        require(newAPR <= 2000, "APR too high"); // Max 20%
        _updateRewards(); // Update with old APR first
        apr = newAPR;
        emit APRUpdated(newAPR);
    }

    /**
     * @notice Set withdrawal delay (only owner)
     * @param newDelay New delay in seconds
     */
    function setWithdrawalDelay(uint256 newDelay) external onlyOwner {
        require(newDelay <= 30 days, "Delay too long");
        withdrawalDelay = newDelay;
    }

    /**
     * @notice Deposit additional ETH to support withdrawals (only owner)
     */
    function depositETH() external payable onlyOwner {
        // Allow owner to add ETH to support withdrawals
    }

    /**
     * @notice Withdraw protocol fees (only owner)
     * @param amount Amount to withdraw
     */
    function withdrawFees(uint256 amount) external onlyOwner {
        require(
            amount <= address(this).balance - totalStaked - totalRewards,
            "Insufficient fees"
        );
        payable(owner()).transfer(amount);
    }

    /**
     * @notice Emergency pause/unpause (only owner)
     * @dev In a real implementation, this would use OpenZeppelin's Pausable
     */
    function emergencyAction() external onlyOwner {
        // Placeholder for emergency functions
        revert("Emergency functions not implemented in mock");
    }

    // ============ Receive Function ============

    /**
     * @notice Receive function to accept ETH deposits
     */
    receive() external payable {
        // Allow contract to receive ETH
    }
}
