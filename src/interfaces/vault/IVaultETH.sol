// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IVault} from "./IVault.sol";

/**
 * @title IVaultETH
 * @notice Interface for ETH-specific vault functionality
 * @dev This interface extends IVault with ETH-specific operations, particularly
 *      rebalancing between different Ethereum liquid staking protocols.
 *      It handles ETH staking across protocols like Lido, RocketPool, EtherFi, etc.
 */
interface IVaultETH is IVault {
    /**
     * @notice Emitted when LST positions are rebalanced between different staking protocols
     * @param fromRouter The source staking router from which LSTs were unstaked
     * @param toRouter The destination staking router to which ETH was staked
     * @param amount The amount of ETH that was rebalanced between protocols
     */
    event PositionRebalanced(
        address indexed fromRouter,
        address indexed toRouter,
        uint256 amount
    );

    /**
     * @notice Rebalances LST positions between different Ethereum staking protocols
     * @dev Unstakes LST tokens from the source router and immediately stakes the resulting
     *      ETH into the destination router. This enables yield optimization and risk management
     *      across multiple liquid staking protocols.
     * @param fromRouter The staking router to unstake LSTs from (e.g., Lido, RocketPool)
     * @param toRouter The staking router to stake ETH into (e.g., EtherFi, Lido)
     * @param amount The amount of LST tokens to rebalance (denominated in LST units)
     */
    function rebalance(
        address fromRouter,
        address toRouter,
        uint256 amount
    ) external;
}
