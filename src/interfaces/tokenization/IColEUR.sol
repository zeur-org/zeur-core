// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title IColEUR
 * @notice Interface for EUR collateral token vault (colEUR)
 * @dev This interface extends ERC4626 vault functionality with additional token transfer
 *      capabilities specific to the EUR debt asset. The colEUR token represents shares
 *      in a vault that holds EUR stablecoins supplied by users to earn yield.
 */
interface IColEUR is IERC4626 {
    /**
     * @notice Transfers underlying EUR tokens to a specified address
     * @dev Allows the vault to transfer underlying EUR tokens directly to recipients
     *      without going through the standard ERC4626 withdrawal process. This is used
     *      for borrowing operations where EUR needs to be transferred to borrowers.
     * @param to The address to receive the EUR tokens
     * @param amount The amount of EUR tokens to transfer
     */
    function transferTokenTo(address to, uint256 amount) external;
}
