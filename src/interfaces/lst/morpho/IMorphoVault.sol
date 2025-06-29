// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title IMorphoVault
 * @notice Interface for Morpho protocol vault contracts
 * @dev This interface extends the standard ERC4626 vault interface for Morpho protocol.
 *      Morpho vaults optimize lending and borrowing yields by automatically rebalancing
 *      between different lending protocols to maximize returns for depositors.
 *      The vault follows ERC4626 standard for tokenized vault interactions.
 */
interface IMorphoVault is IERC4626 {
    // This interface inherits all ERC4626 functionality:
    // - deposit(): Deposit assets and receive vault shares
    // - withdraw(): Burn shares and receive assets
    // - mint(): Mint exact shares by depositing assets
    // - redeem(): Redeem exact shares for assets
    // - previewDeposit(): Preview shares received for asset deposit
    // - previewWithdraw(): Preview shares burned for asset withdrawal
    // - previewMint(): Preview assets needed to mint shares
    // - previewRedeem(): Preview assets received for share redemption
    // - maxDeposit(): Maximum assets that can be deposited
    // - maxWithdraw(): Maximum assets that can be withdrawn
    // - maxMint(): Maximum shares that can be minted
    // - maxRedeem(): Maximum shares that can be redeemed
    // - totalAssets(): Total assets managed by the vault
    // - convertToShares(): Convert asset amount to share amount
    // - convertToAssets(): Convert share amount to asset amount
}
