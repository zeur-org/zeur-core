## Roles List

#### 1. POOL_INIT_RESERVE_ROLE (PoolAdmin, ProtocolSettingManager contract)

- Pool: initCollateralAsset, initDebtAsset

#### 2. VAULT_SETUP_ROLE (VaultAdmin)

- VaultETH: addStakingRouter, removeStakingRouter, updateCurrentStakingRouter, updateCurrentUnstakingRouter
- VaultLINK: addStakingRouter, removeStakingRouter, updateCurrentStakingRouter, updateCurrentUnstakingRouter

#### 3. VAULT_LOCK_COLLATERAL_ROLE (Pool contract)

- VaultETH: lockCollateral, unlockCollateral
- VaultLINK: lockCollateral, unlockCollateral

#### 4. MINTER_BURNER_ROLE (Pool contract)

- ColETH: mint/burn
- ColLINK: mint/burn
- ColEUR: mint/burn
- DebtEUR: mint/burn

#### 5. ROUTER_SETUP (RouterAdmin)

- StakingRouterETHLido:
- StakingRouterETHMorpho:
- StakingRouterETHEtherfi:
- StakingRouterETHRocketPool:
- StakingRouterLINK:

#### 6. ROUTER_ETH_VAULT (VaultETH contract)

- StakingRouterETHLido: stake/unstake
- StakingRouterETHMorpho: stake/unstake
- StakingRouterETHEtherfi: stake/unstake
- StakingRouterETHRocketPool: stake/unstake

#### 7. ROUTER_LINK_VAULT (VaultLINK contract)

- StakingRouterLINK: stake/unstake
