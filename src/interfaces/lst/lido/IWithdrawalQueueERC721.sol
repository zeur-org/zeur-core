// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IWithdrawalQueueERC721 {
    struct WithdrawalRequestStatus {
        uint256 amountOfStETH;
        uint256 amountOfShares;
        address owner;
        uint256 timestamp;
        bool isFinalized;
        bool isClaimed;
    }

    function requestWithdrawals(
        uint256[] calldata _amounts,
        address _owner
    ) external returns (uint256[] memory requestIds);

    function requestWithdrawalsWstETH(
        uint256[] calldata _amounts,
        address _owner
    ) external returns (uint256[] memory requestIds);

    function claimWithdrawal(uint256 _requestId) external;

    function claimWithdrawals(
        uint256[] calldata _requestIds,
        uint256[] calldata _hints
    ) external;

    function claimWithdrawalsTo(
        uint256[] calldata _requestIds,
        uint256[] calldata _hints,
        address _recipient
    ) external;

    function getWithdrawalRequests(
        address _owner
    ) external view returns (uint256[] memory requestsIds);

    function getWithdrawalStatus(
        uint256[] calldata _requestIds
    ) external view returns (WithdrawalRequestStatus[] memory statuses);

    function getClaimableEther(
        uint256[] calldata _requestIds,
        uint256[] calldata _hints
    ) external view returns (uint256[] memory claimableEthValues);
}
