| RoleId | Role lable                 | Assigned address | Contract                   | Functions                    | Remarks |
| ------ | -------------------------- | ---------------- | -------------------------- | ---------------------------- | ------- |
| 1      | POOL_INIT_RESERVE_ROLE     | poolAdmin        | Pool                       | initCollateralAsset          |         |
|        |                            |                  | Pool                       | initDebtAsset                |         |
| 2      | VAULT_SETUP_ROLE           | vaultAdmin       | VaultETH                   | addStakingRouter             |         |
|        |                            |                  |                            | removeStakingRouter          |         |
|        |                            |                  |                            | updateCurrentStakingRouter   |         |
|        |                            |                  |                            | updateCurrentUnstakingRouter |         |
|        |                            |                  | VaultLINK                  | addStakingRouter             |         |
|        |                            |                  |                            | removeStakingRouter          |         |
|        |                            |                  |                            | updateCurrentStakingRouter   |         |
|        |                            |                  |                            | updateCurrentUnstakingRouter |         |
| 3      | VAULT_LOCK_COLLATERAL_ROLE | Pool             | VaultETH                   | lockCollateral               |         |
|        |                            |                  |                            | unlockCollateral             |         |
|        |                            |                  |                            | rebalance                    |         |
|        |                            |                  | VaultLINK                  | lockCollateral               |         |
|        |                            |                  |                            | unlockCollateral             |         |
|        |                            |                  |                            | rebalance                    |         |
| 4      | MINTER_BURNER_ROLE         | Pool             | ColETH                     | mint/burn                    |         |
|        |                            |                  | ColLINK                    | mint/burn                    |         |
|        |                            |                  | ColEUR                     | mint/burn                    |         |
|        |                            |                  | DebtEUR                    | mint/burn                    |         |
| 5      | ROUTER_SETUP               | routerAdmin      | StakingRouterETHLido       |                              |         |
|        |                            |                  | StakingRouterETHMorpho     |                              |         |
|        |                            |                  | StakingRouterETHEtherfi    |                              |         |
|        |                            |                  | StakingRouterETHRocketPool |                              |         |
|        |                            |                  | StakingRouterLINK          |                              |         |
| 6      | ROUTER_ETH_VAULT           | VaultETH         | StakingRouterETHLido       | stake/unstake                |         |
|        |                            |                  | StakingRouterETHMorpho     | stake/unstake                |         |
|        |                            |                  | StakingRouterETHEtherfi    | stake/unstake                |         |
|        |                            |                  | StakingRouterETHRocketPool | stake/unstake                |         |
| 7      | ROUTER_LINK_VAULT          | VaultLINK        | StakingRouterLINK          | stake/unstake                |         |
