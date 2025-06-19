// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title IeETH interface (simplified)
/// @dev Provided for reference by the MockLiquidityPool
interface IeETH {
    function mintShares(address _user, uint256 _share) external;

    function burnShares(address _user, uint256 _share) external;
}

/**
 * @title MockLiquidityPool
 * @dev Mock Ether.fi Liquidity Pool for testing deposit/withdraw of ETH <=> eETH (ERC4626-like behavior)
 */
contract MockLiquidityPool {
    error MockLiquidityPool_FailedToTransfer();

    IeETH public immutable eETH;

    /**
     * @param _eETH Address of the eETH token implementing IeETH
     */
    constructor(address _eETH) {
        eETH = IeETH(_eETH);
    }

    /**
     * @notice Deposit ETH and mint corresponding eETH shares
     * @return sharesMinted Amount of eETH shares minted
     */
    function deposit() public payable returns (uint256 sharesMinted) {
        uint256 amount = msg.value;
        require(amount > 0, "MockLiquidityPool: deposit zero");
        // Mint 1:1 eETH shares to sender
        eETH.mintShares(msg.sender, amount);
        return amount;
    }

    /**
     * @notice Withdraw by burning eETH shares and receiving ETH
     * @param _recipient Address to receive the withdrawn ETH
     * @param _amount Amount of eETH shares to burn (and ETH to send)
     * @return ethSent Amount of ETH transferred to recipient
     */
    function withdraw(
        address _recipient,
        uint256 _amount
    ) external returns (uint256 ethSent) {
        require(_amount > 0, "MockLiquidityPool: withdraw zero");
        // Burn shares from sender
        eETH.burnShares(msg.sender, _amount);
        // Transfer ETH back to recipient
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        if (!success) revert MockLiquidityPool_FailedToTransfer();
        return _amount;
    }

    /// @dev Allow direct ETH transfers to trigger deposit
    receive() external payable {
        deposit();
    }

    /// @dev Allow contract to accept ETH (e.g., for withdrawal liquidity)
    fallback() external payable {}
}

/**
 * @title MockEETH
 * @dev Mock implementation of Ether.fi's eETH token for testing purposes.
 *      Based on ERC20 and ERC20Permit for off-chain approvals.
 */
contract MockEETH is ERC20 {
    constructor() ERC20("Mock Ether.fi eETH", "eETH") {}

    /**
     * @dev Mint shares to a user. Callable only by pool.
     */
    function mintShares(address _user, uint256 _share) external {
        _mint(_user, _share);
    }

    /**
     * @dev Burn shares from a user. Callable only by pool.
     */
    function burnShares(address _user, uint256 _share) external {
        _burn(_user, _share);
    }

    /**
     * @dev Returns total shares (total supply).
     */
    function totalShares() external view returns (uint256) {
        return totalSupply();
    }

    /**
     * @dev Returns user shares (balanceOf).
     */
    function shares(address _user) external view returns (uint256) {
        return balanceOf(_user);
    }
}
