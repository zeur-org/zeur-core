// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MockRETH
 * @dev Mock implementation of Rocket Pool rETH token
 */
contract MockRETH is ERC20 {
    // ============ State Variables ============

    /// @notice Total ETH backing the rETH tokens
    uint256 public totalETHValue;

    /// @notice Exchange rate multiplier for testing (basis points)
    uint256 public exchangeRateMultiplier = 10000; // 1.0x initially

    // ============ Events ============

    event ExchangeRateUpdated(uint256 newRate);

    error MockRETH_FailedToTransfer();

    // ============ Constructor ============

    constructor() ERC20("Rocket Pool ETH", "rETH") {
        totalETHValue = 0;
    }

    // ============ IRETH Functions ============

    /**
     * @notice Get ETH value for given rETH amount
     * @param _rethAmount Amount of rETH
     * @return ETH value
     */
    function getEthValue(uint256 _rethAmount) external view returns (uint256) {
        if (totalSupply() == 0) return _rethAmount;
        return (_rethAmount * totalETHValue) / totalSupply();
    }

    /**
     * @notice Get rETH value for given ETH amount
     * @param _ethAmount Amount of ETH
     * @return rETH value
     */
    function getRethValue(uint256 _ethAmount) external view returns (uint256) {
        if (totalETHValue == 0) return _ethAmount; // 1:1 initially
        return (_ethAmount * totalSupply()) / totalETHValue;
    }

    /**
     * @notice Get current exchange rate (ETH per rETH)
     * @return Exchange rate with 18 decimals
     */
    function getExchangeRate() external view returns (uint256) {
        if (totalSupply() == 0) return 1 ether; // 1:1 initially
        return (totalETHValue * 1 ether) / totalSupply();
    }

    /**
     * @notice Get total collateral (same as total ETH value for mock)
     * @return Total collateral amount
     */
    function getTotalCollateral() external view returns (uint256) {
        return totalETHValue;
    }

    /**
     * @notice Get collateral rate (ratio of collateral to supply)
     * @return Collateral rate with 18 decimals
     */
    function getCollateralRate() external view returns (uint256) {
        if (totalSupply() == 0) return 1 ether;
        return (totalETHValue * 1 ether) / totalSupply();
    }

    /**
     * @notice Mint rETH tokens (only callable by DepositPool)
     * @param _ethAmount Amount of ETH being deposited
     * @param _to Address to mint rETH to
     */
    function mint(uint256 _ethAmount, address _to) external {
        uint256 rethAmount = _ethAmount;
        if (totalETHValue > 0 && totalSupply() > 0) {
            rethAmount = (_ethAmount * totalSupply()) / totalETHValue;
        }

        totalETHValue += _ethAmount;
        _mint(_to, rethAmount);
    }

    /**
     * @notice Burn rETH tokens and calculate ETH to return
     * @param _rethAmount Amount of rETH to burn
     */
    function burn(uint256 _rethAmount) external {
        require(
            balanceOf(msg.sender) >= _rethAmount,
            "Insufficient rETH balance"
        );

        uint256 ethAmount = _rethAmount;
        if (totalSupply() > 0) {
            ethAmount = (_rethAmount * totalETHValue) / totalSupply();
        }

        totalETHValue -= ethAmount;
        _burn(msg.sender, _rethAmount);

        // Transfer ETH back to user
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        if (!success) revert MockRETH_FailedToTransfer();
    }

    // ============ Admin Functions (for testing) ============

    /**
     * @notice Update exchange rate for testing purposes
     * @param _multiplier New exchange rate multiplier (basis points)
     */
    function setExchangeRateMultiplier(uint256 _multiplier) external {
        require(_multiplier > 0, "Invalid multiplier");
        exchangeRateMultiplier = _multiplier;

        // Apply multiplier to total ETH value to simulate rewards
        totalETHValue = (totalETHValue * _multiplier) / 10000;

        emit ExchangeRateUpdated(_multiplier);
    }

    // ============ Receive Function ============

    receive() external payable {
        // Accept ETH for burns and rewards
    }
}

/**
 * @title MockRocketDepositPool
 * @dev Simple mock implementation of Rocket Pool Deposit Pool
 */
contract MockRocketDepositPool {
    // ============ State Variables ============

    /// @notice rETH token contract
    MockRETH public immutable rethToken;

    /// @notice Minimum deposit amount
    uint256 public constant MIN_DEPOSIT = 0.01 ether;

    // ============ Events ============

    event Deposited(
        address indexed user,
        uint256 ethAmount,
        uint256 rethAmount
    );

    // ============ Constructor ============

    constructor(address _rethToken) {
        require(_rethToken != address(0), "Invalid rETH token address");
        rethToken = MockRETH(payable(_rethToken));
    }

    // ============ Core Function ============

    /**
     * @notice Deposit ETH and receive rETH tokens
     */
    function deposit() external payable {
        require(msg.value >= MIN_DEPOSIT, "Below minimum deposit");

        uint256 ethAmount = msg.value;

        // Calculate rETH amount to mint
        uint256 rethAmount = ethAmount;
        if (rethToken.totalETHValue() > 0 && rethToken.totalSupply() > 0) {
            rethAmount = rethToken.getRethValue(ethAmount);
        }

        // Transfer ETH to rETH contract
        payable(address(rethToken)).call{value: ethAmount}("");

        // Mint rETH to user
        rethToken.mint(ethAmount, msg.sender);

        emit Deposited(msg.sender, ethAmount, rethAmount);
    }

    // ============ View Functions ============

    /**
     * @notice Get rETH token address
     * @return rETH token address
     */
    function getRETHToken() external view returns (address) {
        return address(rethToken);
    }

    /**
     * @notice Get minimum deposit amount
     * @return Minimum deposit amount
     */
    function getMinimumDeposit() external pure returns (uint256) {
        return MIN_DEPOSIT;
    }
}

contract MockRocketDAOSettings {
    function getDepositFee() external pure returns (uint256) {
        return 0; // Protocol fee = 0 for simplification
    }
}
