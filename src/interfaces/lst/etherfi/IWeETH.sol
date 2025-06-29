// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILiquidityPool} from "./ILiquidityPool.sol";
import {IeETH} from "./IeETH.sol";

/**
 * @title IWeETH
 * @notice Interface for EtherFi's weETH (wrapped eETH) liquid staking token
 * @dev This interface extends ERC20 with EtherFi-specific functionality for weETH,
 *      which is a wrapped version of eETH that automatically compounds staking rewards.
 *      weETH maintains an appreciating exchange rate relative to eETH and ETH.
 */
interface IWeETH is IERC20 {
    /**
     * @notice Struct for permit signature parameters
     * @dev Used for gasless approval transactions via EIP-2612 permit functionality
     */
    struct PermitInput {
        uint256 value; /// @dev The approval amount
        uint256 deadline; /// @dev The permit expiration timestamp
        uint8 v; /// @dev ECDSA signature recovery identifier
        bytes32 r; /// @dev ECDSA signature first 32 bytes
        bytes32 s; /// @dev ECDSA signature second 32 bytes
    }

    // STATE VARIABLES

    /**
     * @notice Returns the underlying eETH token contract
     * @dev The eETH token that this weETH contract wraps
     * @return The IeETH interface of the underlying eETH token
     */
    function eETH() external view returns (IeETH);

    /**
     * @notice Returns the EtherFi liquidity pool contract
     * @dev The main liquidity pool that manages ETH staking and eETH minting
     * @return The ILiquidityPool interface of the liquidity pool
     */
    function liquidityPool() external view returns (ILiquidityPool);

    /**
     * @notice Checks if an address is a whitelisted spender
     * @dev Whitelisted spenders may have special privileges or reduced restrictions
     * @param spender The address to check
     * @return True if the spender is whitelisted, false otherwise
     */
    function whitelistedSpender(address spender) external view returns (bool);

    /**
     * @notice Checks if an address is a blacklisted recipient
     * @dev Blacklisted recipients cannot receive weETH transfers
     * @param recipient The address to check
     * @return True if the recipient is blacklisted, false otherwise
     */
    function blacklistedRecipient(
        address recipient
    ) external view returns (bool);

    // STATE-CHANGING FUNCTIONS

    /**
     * @notice Initializes the weETH contract
     * @dev Sets up the contract with the liquidity pool and eETH token addresses
     * @param _liquidityPool The address of the EtherFi liquidity pool
     * @param _eETH The address of the eETH token contract
     */
    function initialize(address _liquidityPool, address _eETH) external;

    /**
     * @notice Wraps eETH tokens into weETH
     * @dev Converts eETH tokens to weETH at the current exchange rate.
     *      weETH automatically compounds rewards over time.
     * @param _eETHAmount The amount of eETH tokens to wrap
     * @return The amount of weETH tokens received
     */
    function wrap(uint256 _eETHAmount) external returns (uint256);

    /**
     * @notice Wraps eETH tokens into weETH using permit for gasless approval
     * @dev Same as wrap() but uses EIP-2612 permit to avoid separate approval transaction
     * @param _eETHAmount The amount of eETH tokens to wrap
     * @param _permit The permit signature parameters for eETH approval
     * @return The amount of weETH tokens received
     */
    function wrapWithPermit(
        uint256 _eETHAmount,
        ILiquidityPool.PermitInput calldata _permit
    ) external returns (uint256);

    /**
     * @notice Unwraps weETH tokens back to eETH
     * @dev Converts weETH tokens back to eETH at the current exchange rate.
     *      The user receives more eETH than they originally wrapped due to compounded rewards.
     * @param _weETHAmount The amount of weETH tokens to unwrap
     * @return The amount of eETH tokens received
     */
    function unwrap(uint256 _weETHAmount) external returns (uint256);

    /**
     * @notice Permits spender to transfer tokens via signature (EIP-2612)
     * @dev Allows gasless approvals by using off-chain signatures
     * @param owner The token owner's address
     * @param spender The address to approve for spending
     * @param value The amount to approve
     * @param deadline The permit expiration timestamp
     * @param v ECDSA signature recovery identifier
     * @param r ECDSA signature first 32 bytes
     * @param s ECDSA signature second 32 bytes
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Sets whitelist status for multiple spenders
     * @dev Admin function to manage spender whitelist for special privileges
     * @param _spenders Array of spender addresses to update
     * @param _isWhitelisted Whether to whitelist (true) or remove from whitelist (false)
     */
    function setWhitelistedSpender(
        address[] calldata _spenders,
        bool _isWhitelisted
    ) external;

    /**
     * @notice Sets blacklist status for multiple recipients
     * @dev Admin function to manage recipient blacklist for compliance
     * @param _recipients Array of recipient addresses to update
     * @param _isBlacklisted Whether to blacklist (true) or remove from blacklist (false)
     */
    function setBlacklistedRecipient(
        address[] calldata _recipients,
        bool _isBlacklisted
    ) external;

    // GETTER FUNCTIONS

    /**
     * @notice Calculates weETH amount that would be received for eETH amount
     * @dev Preview function for wrap operations - shows exchange rate without executing
     * @param _eETHAmount The amount of eETH to convert
     * @return The equivalent amount of weETH
     */
    function getWeETHByeETH(
        uint256 _eETHAmount
    ) external view returns (uint256);

    /**
     * @notice Calculates eETH amount that would be received for weETH amount
     * @dev Preview function for unwrap operations - shows exchange rate without executing
     * @param _weETHAmount The amount of weETH to convert
     * @return The equivalent amount of eETH
     */
    function getEETHByWeETH(
        uint256 _weETHAmount
    ) external view returns (uint256);

    /**
     * @notice Returns the current weETH to eETH exchange rate
     * @dev The rate represents how much eETH is backing each weETH token.
     *      This rate increases over time as staking rewards compound.
     * @return The current exchange rate (weETH value in eETH)
     */
    function getRate() external view returns (uint256);

    /**
     * @notice Returns the implementation contract address
     * @dev For proxy contracts, returns the address of the implementation logic
     * @return The address of the implementation contract
     */
    function getImplementation() external view returns (address);
}
