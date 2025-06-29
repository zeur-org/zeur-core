// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IWETH
 * @notice Interface for Wrapped Ether (WETH) contract
 * @dev This interface provides functionality to wrap native ETH into an ERC20-compatible
 *      token (WETH) and unwrap it back to native ETH. WETH maintains a 1:1 peg with ETH
 *      and is used throughout DeFi protocols for standardized token interactions.
 */
interface IWETH {
    /**
     * @notice Wraps native ETH into WETH tokens
     * @dev Converts the sent ETH (msg.value) into an equivalent amount of WETH tokens.
     *      The WETH tokens are minted to the sender's address at a 1:1 ratio with ETH.
     */
    function deposit() external payable;

    /**
     * @notice Unwraps WETH tokens back to native ETH
     * @dev Burns the specified amount of WETH tokens and transfers equivalent native ETH
     *      to the sender. The conversion rate is always 1:1.
     * @param amount The amount of WETH tokens to unwrap to ETH
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Approves spender to transfer WETH tokens on behalf of the owner
     * @dev Standard ERC20 approve function allowing another address to spend
     *      the owner's WETH tokens up to the specified amount.
     * @param guy The address to approve as spender
     * @param wad The amount of WETH tokens to approve for spending
     * @return success Boolean indicating whether the approval was successful
     */
    function approve(address guy, uint256 wad) external returns (bool success);

    /**
     * @notice Transfers WETH tokens from one address to another
     * @dev Standard ERC20 transferFrom function that moves WETH tokens from the
     *      source address to the destination address. Requires prior approval.
     * @param src The source address to transfer WETH from
     * @param dst The destination address to transfer WETH to
     * @param wad The amount of WETH tokens to transfer
     * @return success Boolean indicating whether the transfer was successful
     */
    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool success);
}
