// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IWithdrawalQueueERC721
 * @notice Interface for Lido's withdrawal queue system
 * @dev This interface handles the withdrawal process for stETH/wstETH holders who want
 *      to convert their liquid staking tokens back to ETH. Due to the nature of
 *      Ethereum staking, withdrawals must go through a queue system and may take time.
 */
interface IWithdrawalQueueERC721 {
    /**
     * @notice Struct containing withdrawal request information
     * @dev Represents the status and details of a withdrawal request in the queue
     */
    struct WithdrawalRequestStatus {
        uint256 amountOfStETH; /// @dev Amount of stETH requested for withdrawal
        uint256 amountOfShares; /// @dev Amount of Lido shares represented by the request
        address owner; /// @dev Address that owns this withdrawal request
        uint256 timestamp; /// @dev Timestamp when the request was created
        bool isFinalized; /// @dev Whether the request has been processed by validators
        bool isClaimed; /// @dev Whether the ETH has been claimed by the owner
    }

    /**
     * @notice Requests withdrawal of stETH tokens to ETH
     * @dev Creates withdrawal requests for the specified amounts of stETH.
     *      Each amount creates a separate NFT representing the withdrawal request.
     * @param _amounts Array of stETH amounts to withdraw
     * @param _owner Address that will own the withdrawal request NFTs
     * @return requestIds Array of NFT token IDs representing the withdrawal requests
     */
    function requestWithdrawals(
        uint256[] calldata _amounts,
        address _owner
    ) external returns (uint256[] memory requestIds);

    /**
     * @notice Requests withdrawal of wstETH tokens to ETH
     * @dev Creates withdrawal requests for the specified amounts of wstETH.
     *      wstETH is converted to stETH before processing the withdrawal request.
     * @param _amounts Array of wstETH amounts to withdraw
     * @param _owner Address that will own the withdrawal request NFTs
     * @return requestIds Array of NFT token IDs representing the withdrawal requests
     */
    function requestWithdrawalsWstETH(
        uint256[] calldata _amounts,
        address _owner
    ) external returns (uint256[] memory requestIds);

    /**
     * @notice Claims ETH for a finalized withdrawal request
     * @dev Transfers the ETH corresponding to a withdrawal request to the owner.
     *      The request must be finalized before it can be claimed.
     * @param _requestId The NFT token ID of the withdrawal request to claim
     */
    function claimWithdrawal(uint256 _requestId) external;

    /**
     * @notice Claims ETH for multiple finalized withdrawal requests
     * @dev Batch version of claimWithdrawal for gas efficiency.
     * @param _requestIds Array of withdrawal request NFT token IDs to claim
     * @param _hints Array of hints to optimize gas usage (can be empty array)
     */
    function claimWithdrawals(
        uint256[] calldata _requestIds,
        uint256[] calldata _hints
    ) external;

    /**
     * @notice Claims ETH for multiple withdrawal requests to a specific recipient
     * @dev Similar to claimWithdrawals but allows specifying a different recipient address.
     * @param _requestIds Array of withdrawal request NFT token IDs to claim
     * @param _hints Array of hints to optimize gas usage (can be empty array)
     * @param _recipient Address to receive the claimed ETH
     */
    function claimWithdrawalsTo(
        uint256[] calldata _requestIds,
        uint256[] calldata _hints,
        address _recipient
    ) external;

    /**
     * @notice Gets all withdrawal request IDs owned by an address
     * @dev Returns an array of NFT token IDs representing withdrawal requests owned by the address.
     * @param _owner The address to query withdrawal requests for
     * @return requestsIds Array of withdrawal request NFT token IDs
     */
    function getWithdrawalRequests(
        address _owner
    ) external view returns (uint256[] memory requestsIds);

    /**
     * @notice Gets the status of multiple withdrawal requests
     * @dev Returns detailed information about each withdrawal request.
     * @param _requestIds Array of withdrawal request NFT token IDs to query
     * @return statuses Array of WithdrawalRequestStatus structs with request details
     */
    function getWithdrawalStatus(
        uint256[] calldata _requestIds
    ) external view returns (WithdrawalRequestStatus[] memory statuses);

    /**
     * @notice Gets the claimable ETH amount for finalized withdrawal requests
     * @dev Returns the amount of ETH that can be claimed for each withdrawal request.
     *      Only finalized requests will have claimable ETH.
     * @param _requestIds Array of withdrawal request NFT token IDs to query
     * @param _hints Array of hints to optimize gas usage (can be empty array)
     * @return claimableEthValues Array of ETH amounts that can be claimed
     */
    function getClaimableEther(
        uint256[] calldata _requestIds,
        uint256[] calldata _hints
    ) external view returns (uint256[] memory claimableEthValues);
}
