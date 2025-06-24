-include .env

# Protocol core contracts
deploy-protocol-access-manager:
	forge script script/DeployProtocolAccessManager.s.sol:DeployProtocolAccessManager --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-chainlink-oracle-manager:
	forge script script/DeployChainlinkOracleManager.s.sol:DeployChainlinkOracleManager --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-protocol-setting-manager:
	forge script script/DeployProtocolSettingManager.s.sol:DeployProtocolSettingManager --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-protocol-vault-manager:
	forge script script/DeployProtocolVaultManager.s.sol:DeployProtocolVaultManager --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-pool:
	forge script script/DeployPool.s.sol:DeployPool --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-pool-data:
	forge script script/DeployPoolData.s.sol:DeployPoolData --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

# Collateral related contracts
deploy-vault-eth:
	forge script script/DeployVaultETH.s.sol:DeployVaultETH --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-vault-link:
	forge script script/DeployVaultLINK.s.sol:DeployVaultLINK --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-col-token:
	forge script script/DeployColToken.s.sol:DeployColToken --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-staking-routers:
	forge script script/DeployStakingRouters.s.sol:DeployStakingRouters --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-mock-link:
	forge script script/DeployMockLINK.s.sol:DeployMockLINK --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

# Debt related contracts
deploy-col-eur:
	forge script script/DeployColEUR.s.sol:DeployColEUR --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-debt-eur:
	forge script script/DeployDebtEUR.s.sol:DeployDebtEUR --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi


deploy-mock-eurc:
	forge script script/DeployMockEURC.s.sol:DeployMockEURC --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

set-roles:
	forge script script/config/SetRoles.s.sol:SetRoles --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast

set-pool-admin:
	forge script script/config/SetPoolAdmin.s.sol:SetPoolAdmin --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast

set-eur-role:
	forge script script/config/SetEurRole.s.sol:SetEurRole --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast

upgrade-pool:
	forge script script/UpgradePool.s.sol:UpgradePool --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

upgrade-pool-data:
	forge script script/UpgradePoolData.s.sol:UpgradePoolData --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

set-mint-approve:
	forge script script/config/SetMintApprove.s.sol:SetMintApprove --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast

set-oracle:
	forge script script/config/SetOracle.s.sol:SetOracle --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast

deploy-mock-morpho:
	forge script script/DeployMockLSTMorpho.s.sol:DeployMockLSTMorpho --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-mock-lido:
	forge script script/DeployMockLSTLido.s.sol:DeployMockLSTLido --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-mock-etherfi:
	forge script script/DeployMockLSTEtherfi.s.sol:DeployMockLSTEtherfi --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-mock-rocket-pool:
	forge script script/DeployMockLSTRocketPool.s.sol:DeployMockLSTRocketPool --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-mock-stake-link:
	forge script script/DeployMockLSTStakeLink.s.sol:DeployMockLSTStakeLink --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi