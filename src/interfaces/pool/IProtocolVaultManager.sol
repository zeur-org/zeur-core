// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IProtocolVaultManager {
    error ProtocolVaultManager__NotDebtAsset(address asset);

    error ProtocolVaultManager__HarvestYieldFailed(
        address router,
        address debtAsset,
        address swapRouter
    );

    event YieldDistributed(
        address indexed router,
        address indexed debtAsset,
        address indexed colToken,
        uint256 debtReceived
    );
}
