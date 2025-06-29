// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IColToken
 * @notice Interface for collateral tokens (colETH, colLINK, etc.)
 * @dev This interface defines the minting and burning functionality for collateral tokens
 *      that represent user deposits in the protocol's vaults. These tokens are minted when
 *      users supply collateral and burned when they withdraw.
 */
interface IColToken {
    /**
     * @notice Mints collateral tokens to a specified address
     * @dev Creates new collateral tokens representing staked assets in the vault.
     *      Only authorized contracts (typically the Pool) can call this function.
     * @param to The address to receive the newly minted collateral tokens
     * @param amount The amount of collateral tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Burns collateral tokens from a specified address
     * @dev Destroys collateral tokens when users withdraw their underlying assets.
     *      Only authorized contracts (typically the Pool) can call this function.
     * @param account The address from which to burn collateral tokens
     * @param value The amount of collateral tokens to burn
     */
    function burn(address account, uint256 value) external;
}
