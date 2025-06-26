// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IProtocolVaultManager {
    error ProtocolVaultManager__NotDebtAsset(address asset);

    event YieldDistributed(
        address indexed colToken,
        address indexed asset,
        uint256 amount
    );
}
