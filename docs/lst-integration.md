## Integration with LST platforms

### Lido (stETH + WithdrawalQueueERC721)

- Stake (stETH): submit(referral)
- Unstake (stETH): requestWithdrawals(uint256[] \_amounts, address \_owner) => claimWithdrawal(requestId)

### Morpho (mWETH + MorphoVault)

- Stake (MorphoVault): deposit(uint256 \_amount, address \_from)
- Unstake (MorphoVault): withdraw(uint256 \_amount, address \_to)

### Etherfi (eETH + LiquidityPool)

- Stake (LiquidityPool): deposit(uint256 \_amount, address \_from)
- Unstake (LiquidityPool): withdraw(uint256 \_amount, address \_to)

### Rocket Pool (rETH + DepositPool)

- Stake (DepositPool): deposit(uint256 \_amount, address \_from)
- Unstake (rETH): burn(uint256 \_amount)

### Chainlink (stETH + PriorityPool)

- Stake (PriorityPool): deposit(uint256 \_amount, bool \_shouldQueue, bytes[] calldata \_data)
- Unstake (PriorityPool): withdraw(uint256 \_amountToWithdraw, uint256 \_amount, uint256 \_sharesAmount, bytes32[] calldata \_merkleProof, bool \_shouldUnqueue, bool \_shouldQueueWithdrawal, bytes[] calldata \_data)
