// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IVault
 * @notice Interface for vault contracts that manage liquid staking token (LST) operations
 * @dev This interface defines the core functionality for vault contracts that handle staking,
 *      unstaking, and yield harvesting across multiple liquid staking protocols.
 *      Vaults serve as the bridge between the lending protocol and various LST providers.
 */
interface IVault {
    /**
     * @notice Thrown when there is insufficient collateral for an operation
     */
    error Vault_InsufficientCollateral();

    /**
     * @notice Thrown when an invalid amount is provided (e.g., zero amount)
     */
    error Vault_InvalidAmount();

    /**
     * @notice Thrown when an invalid or unregistered staking router is used
     * @param router The address of the invalid staking router
     */
    error Vault_InvalidStakingRouter(address router);

    /**
     * @notice Thrown when attempting to add a staking router that is already registered
     * @param router The address of the staking router that was already added
     */
    error Vault_StakingRouterAlreadyAdded(address router);

    /**
     * @notice Thrown when attempting to remove a staking router that is already removed
     * @param router The address of the staking router that was already removed
     */
    error Vault_StakingRouterAlreadyRemoved(address router);

    /**
     * @notice Thrown when yield harvesting operation fails
     */
    error Vault_HarvestYieldFailed();

    /**
     * @notice Emitted when a new staking router is added to the vault
     * @param router The address of the added staking router
     */
    event StakingRouterAdded(address indexed router);

    /**
     * @notice Emitted when a staking router is removed from the vault
     * @param router The address of the removed staking router
     */
    event StakingRouterRemoved(address indexed router);

    /**
     * @notice Emitted when the current staking router is updated
     * @param router The address of the new current staking router
     */
    event CurrentStakingRouterUpdated(address indexed router);

    /**
     * @notice Emitted when the current unstaking router is updated
     * @param router The address of the new current unstaking router
     */
    event CurrentUnstakingRouterUpdated(address indexed router);

    /**
     * @notice Emitted when yield is harvested from a staking protocol
     * @param router The staking router from which yield was harvested
     * @param debtAsset The debt asset that the yield was converted to
     * @param amount The amount of yield harvested
     */
    event YieldHarvested(
        address indexed router,
        address indexed debtAsset,
        uint256 amount
    );

    /**
     * @notice Register a new staking router for the vault
     * @dev Adds a staking router to the list of available protocols.
     *      The router must implement IStakingRouter interface.
     * @param router Address of the StakingRouter contract
     */
    function addStakingRouter(address router) external;

    /**
     * @notice Remove an existing staking router from the vault
     * @dev Removes a staking router from the list of available protocols.
     *      Cannot remove the currently active staking or unstaking router.
     * @param router Address of the StakingRouter contract to remove
     */
    function removeStakingRouter(address router) external;

    /**
     * @notice Update the current staking router used for new deposits
     * @dev Changes which staking router will be used for future staking operations.
     *      The router must already be registered in the vault.
     * @param router Address of the StakingRouter to set as current
     */
    function updateCurrentStakingRouter(address router) external;

    /**
     * @notice Update the current unstaking router used for withdrawals
     * @dev Changes which staking router will be used for future unstaking operations.
     *      The router must already be registered in the vault.
     * @param router Address of the StakingRouter to set as current for unstaking
     */
    function updateCurrentUnstakingRouter(address router) external;

    /**
     * @notice Get the current unstaking router address
     * @dev Returns the router currently being used for unstaking operations
     * @return The address of the current unstaking router
     */
    function getCurrentUnstakingRouter() external view returns (address);

    /**
     * @notice Get the current staking router address
     * @dev Returns the router currently being used for staking operations
     * @return The address of the current staking router
     */
    function getCurrentStakingRouter() external view returns (address);

    /**
     * @notice List all registered staking routers
     * @dev Returns an array of all staking router addresses registered with this vault
     * @return Array of staking router addresses
     */
    function getStakingRouters() external view returns (address[] memory);

    /**
     * @notice Stakes user assets into the selected LST protocol
     * @dev Locks collateral by staking it through the current staking router.
     *      For ETH vaults, the function should be payable and msg.value should equal amount.
     *      For token vaults, tokens should be transferred before calling this function.
     * @param from The address of the user providing the collateral (typically the Pool contract)
     * @param amount Amount of underlying asset to stake
     */
    function lockCollateral(address from, uint256 amount) external payable;

    /**
     * @notice Unstakes LSTs back to underlying asset for user withdrawal
     * @dev Unlocks collateral by unstaking LSTs through the current unstaking router.
     *      The unstaked assets are sent to the specified address.
     * @param to The address to receive the unstaked underlying assets
     * @param amount Amount of underlying asset equivalent to unstake
     */
    function unlockCollateral(address to, uint256 amount) external;

    /**
     * @notice Harvest yield generated from staking rewards
     * @dev Extracts accumulated staking rewards from the specified router.
     *      The yield is typically transferred to the caller (VaultManager) for further processing.
     * @param router Address of the StakingRouter to harvest yield from
     * @return lstToken The address of the LST token that yield was harvested in
     * @return yieldAmount The amount of yield harvested
     */
    function harvestYield(
        address router
    ) external returns (address lstToken, uint256 yieldAmount);
}
