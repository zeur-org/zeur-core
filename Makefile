-include .env

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

deploy-vault-eth:
	forge script script/DeployVaultETH.s.sol:DeployVaultETH --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-vault-link:
	forge script script/DeployVaultLINK.s.sol:DeployVaultLINK --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-col-token:
	forge script script/DeployColToken.s.sol:DeployColToken --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-col-eur:
	forge script script/DeployColEUR.s.sol:DeployColEUR --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-debt-eur:
	forge script script/DeployDebtEUR.s.sol:DeployDebtEUR --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-staking-routers:
	forge script script/DeployStakingRouters.s.sol:DeployStakingRouters --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

deploy-mock-eurc:
	forge script script/DeployMockEURC.s.sol:DeployMockEURC --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --ffi

set-roles:
	forge script script/config/SetRoles.s.sol:SetRoles --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast

set-pool-admin:
	forge script script/config/SetPoolAdmin.s.sol:SetPoolAdmin --rpc-url sepolia --private-key ${PRIVATE_KEY} --broadcast