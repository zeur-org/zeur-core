// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IDebtEUR
 * @notice Interface for EUR debt tokens (debtEUR)
 * @dev This interface defines the minting and burning functionality for debt tokens
 *      that represent user borrowing positions in EUR stablecoins. These tokens are
 *      minted when users borrow EUR and burned when they repay their debt.
 */
interface IDebtEUR {
    /**
     * @notice Mints debt tokens to a specified address
     * @dev Creates new debt tokens representing borrowed EUR amounts.
     *      Only authorized contracts (typically the Pool) can call this function.
     *      This increases the borrower's debt balance in the protocol.
     * @param to The address to receive the newly minted debt tokens (the borrower)
     * @param amount The amount of debt tokens to mint (equal to EUR borrowed)
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Burns debt tokens from a specified address
     * @dev Destroys debt tokens when users repay their EUR debt.
     *      Only authorized contracts (typically the Pool) can call this function.
     *      This decreases the borrower's debt balance in the protocol.
     * @param account The address from which to burn debt tokens (the borrower)
     * @param value The amount of debt tokens to burn (equal to EUR repaid)
     */
    function burn(address account, uint256 value) external;
}
