// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MockstLINK
 * @dev Simple ERC4626 vault token representing staked LINK
 */
contract MockstLINK is ERC4626 {
    constructor(
        address _linkToken
    ) ERC4626(IERC20(_linkToken)) ERC20("Staked LINK", "stLINK") {
        require(_linkToken != address(0), "Invalid LINK token address");
    }

    /**
     * @notice Mint stLINK tokens (only callable by PriorityPool)
     * @param to Address to mint tokens to
     * @param amount Amount of stLINK to mint
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @notice Burn stLINK tokens (only callable by PriorityPool)
     * @param from Address to burn tokens from
     * @param amount Amount of stLINK to burn
     */
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

/**
 * @title MockPriorityPool
 * @dev Simple mock implementation of Chainlink Priority Pool for LINK staking
 * Users interact with this contract to deposit LINK and receive stLINK tokens
 */
contract MockPriorityPool {
    // ============ State Variables ============

    /// @notice LINK token contract
    IERC20 public immutable linkToken;

    /// @notice stLINK token contract
    MockstLINK public immutable stLinkToken;

    // ============ Events ============

    event Deposited(
        address indexed user,
        uint256 linkAmount,
        uint256 stLinkAmount
    );
    event Withdrawn(
        address indexed user,
        uint256 stLinkAmount,
        uint256 linkAmount
    );

    // ============ Constructor ============

    constructor(address _linkToken, address _stLinkToken) {
        require(_linkToken != address(0), "Invalid LINK token address");
        require(_stLinkToken != address(0), "Invalid stLINK token address");

        linkToken = IERC20(_linkToken);
        stLinkToken = MockstLINK(_stLinkToken);
    }

    // ============ Core Functions ============

    /**
     * @notice Deposit LINK tokens and receive stLINK, keep the same interface as Stake.Link priority pool
     * @param _amount Amount of LINK to deposit
     */
    function deposit(
        uint256 _amount,
        bool _shouldQueue,
        bytes[] calldata _data
    ) external {
        require(_amount > 0, "Amount must be greater than 0");

        // Transfer LINK from user to this contract
        require(
            linkToken.transferFrom(msg.sender, address(this), _amount),
            "LINK transfer failed"
        );

        // Calculate stLINK amount (1:1 for simplicity, can be modified for exchange rate)
        uint256 stLinkAmount = _amount;

        // Mint stLINK tokens to user
        stLinkToken.mint(msg.sender, stLinkAmount);

        emit Deposited(msg.sender, _amount, stLinkAmount);
    }

    /**
     * @notice Withdraw LINK tokens by burning stLINK
     * @param _amountToWithdraw Amount of stLINK to burn
     */
    function withdraw(
        uint256 _amountToWithdraw,
        uint256 _amount,
        uint256 _sharesAmount,
        bytes32[] calldata _merkleProof,
        bool _shouldUnqueue,
        bool _shouldQueueWithdrawal,
        bytes[] calldata _data
    ) external {
        require(_amountToWithdraw > 0, "Amount must be greater than 0");
        require(
            stLinkToken.balanceOf(msg.sender) >= _amountToWithdraw,
            "Insufficient stLINK balance"
        );

        // Calculate LINK amount (1:1 for simplicity, can be modified for exchange rate)
        uint256 linkAmount = _amountToWithdraw;

        // Ensure contract has enough LINK to withdraw
        require(
            linkToken.balanceOf(address(this)) >= linkAmount,
            "Insufficient LINK in pool"
        );

        // Burn stLINK tokens from user
        stLinkToken.burn(msg.sender, _amountToWithdraw);

        // Transfer LINK back to user
        require(
            linkToken.transfer(msg.sender, linkAmount),
            "LINK transfer failed"
        );

        emit Withdrawn(msg.sender, _amountToWithdraw, linkAmount);
    }

    // ============ View Functions ============

    /**
     * @notice Get the current exchange rate (LINK per stLINK)
     * @return Exchange rate with 18 decimals (1e18 = 1:1)
     */
    function getExchangeRate() external pure returns (uint256) {
        return 1e18; // 1:1 exchange rate for simplicity
    }

    /**
     * @notice Get total LINK deposited in the pool
     * @return Total LINK balance
     */
    function getTotalDeposits() external view returns (uint256) {
        return linkToken.balanceOf(address(this));
    }

    /**
     * @notice Get total stLINK tokens minted
     * @return Total stLINK supply
     */
    function getTotalStLinkSupply() external view returns (uint256) {
        return stLinkToken.totalSupply();
    }
}
