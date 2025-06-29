// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IsAVAX
 * @notice Interface for sAVAX liquid staking token on Avalanche
 * @dev This interface provides functionality for stacking AVAX and receiving sAVAX tokens
 *      in return. sAVAX represents staked AVAX and accrues staking rewards over time.
 *      This follows a similar pattern to other liquid staking tokens but for the Avalanche network.
 */
interface IsAVAX {
    /**
     * @notice Stakes AVAX and mints sAVAX tokens to the sender
     * @dev Submits AVAX for staking and receives sAVAX tokens in return.
     *      The exchange rate may not be 1:1 as sAVAX appreciates over time with rewards.
     * @return The amount of sAVAX tokens minted to the sender
     */
    function submit() external payable returns (uint256);

    /**
     * @notice Burns sAVAX tokens and withdraws AVAX
     * @dev Allows users to unstake their sAVAX tokens and receive underlying AVAX.
     *      The amount of AVAX received will typically be more than originally staked due to rewards.
     * @param amount The amount of sAVAX tokens to burn for withdrawal
     * @return The amount of AVAX withdrawn
     */
    function withdraw(uint256 amount) external returns (uint256);

    /**
     * @notice Returns the name of the token
     * @dev Standard ERC20 function returning the token name
     * @return The token name (e.g., "Staked AVAX")
     */
    function name() external pure returns (string memory);

    /**
     * @notice Returns the symbol of the token
     * @dev Standard ERC20 function returning the token symbol
     * @return The token symbol ("sAVAX")
     */
    function symbol() external pure returns (string memory);

    /**
     * @notice Returns the number of decimals for the token
     * @dev Standard ERC20 function returning decimal places
     * @return The number of decimals (typically 18)
     */
    function decimals() external pure returns (uint8);

    /**
     * @notice Returns the total number of shares in the staking pool
     * @dev Internal accounting mechanism for tracking proportional ownership
     * @return The total shares outstanding
     */
    function totalShares() external view returns (uint256);

    /**
     * @notice Returns the total supply of sAVAX tokens
     * @dev Standard ERC20 function returning total token supply
     * @return The total supply of sAVAX tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the sAVAX balance of a specific address
     * @dev Standard ERC20 function returning account balance
     * @param _user The address to query the balance for
     * @return The sAVAX token balance of the specified address
     */
    function balanceOf(address _user) external view returns (uint256);

    /**
     * @notice Transfers sAVAX tokens from one address to another
     * @dev Standard ERC20 transferFrom function with allowance mechanism
     * @param _sender The address to transfer tokens from
     * @param _recipient The address to transfer tokens to
     * @param _amount The amount of tokens to transfer
     * @return True if the transfer was successful
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    /**
     * @notice Transfers sAVAX tokens to a specified address
     * @dev Standard ERC20 transfer function
     * @param _recipient The address to transfer tokens to
     * @param _amount The amount of tokens to transfer
     * @return True if the transfer was successful
     */
    function transfer(
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    /**
     * @notice Approves another address to spend sAVAX tokens on behalf of the owner
     * @dev Standard ERC20 approve function for allowance mechanism
     * @param _spender The address to approve for spending
     * @param _amount The amount of tokens to approve
     * @return True if the approval was successful
     */
    function approve(address _spender, uint256 _amount) external returns (bool);
}
