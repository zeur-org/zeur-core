// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Core contracts
import {Pool} from "../pool/Pool.sol";
import {PoolData} from "../pool/PoolData.sol";
import {ProtocolAccessManager} from "../pool/manager/ProtocolAccessManager.sol";
import {ProtocolSettingManager} from "../pool/manager/ProtocolSettingManager.sol";
import {ProtocolVaultManager} from "../pool/manager/ProtocolVaultManager.sol";
import {ChainlinkOracleManager} from "../chainlink/ChainlinkOracleManager.sol";
// Staking routers
import {StakingRouterLINK} from "../pool/router/StakingRouterLINK.sol";
import {StakingRouterETHLido} from "../pool/router/StakingRouterETHLido.sol";
import {StakingRouterETHMorpho} from "../pool/router/StakingRouterETHMorpho.sol";
import {StakingRouterETHEtherfi} from "../pool/router/StakingRouterETHEtherfi.sol";
import {StakingRouterETHRocketPool} from "../pool/router/StakingRouterETHRocketPool.sol";
// Tokenization
import {ColEUR} from "../pool/tokenization/ColEUR.sol";
import {ColToken} from "../pool/tokenization/ColToken.sol";
import {DebtEUR} from "../pool/tokenization/DebtEUR.sol";
// Vaults
import {VaultETH} from "../pool/vault/VaultETH.sol";
import {VaultLINK} from "../pool/vault/VaultLINK.sol";

library Roles {
    uint64 constant SETTING_MANAGER_ADMIN_ROLE = 1;
    uint64 constant POOL_INIT_RESERVE_ROLE = 2;
    uint64 constant VAULT_SETUP_ROLE = 3;
    uint64 constant VAULT_LOCK_COLLATERAL_ROLE = 4;
    uint64 constant MINTER_BURNER_ROLE = 5;
    uint64 constant ROUTER_SETUP_ROLE = 6;
    uint64 constant ROUTER_ETH_VAULT_ROLE = 7;
    uint64 constant ROUTER_LINK_VAULT_ROLE = 8;

    string constant SETTING_MANAGER_ADMIN_ROLE_NAME =
        "SETTING_MANAGER_ADMIN_ROLE";
    string constant POOL_INIT_RESERVE_ROLE_NAME = "POOL_INIT_RESERVE_ROLE";
    string constant VAULT_SETUP_ROLE_NAME = "VAULT_SETUP_ROLE";
    string constant VAULT_LOCK_COLLATERAL_ROLE_NAME =
        "VAULT_LOCK_COLLATERAL_ROLE";
    string constant MINTER_BURNER_ROLE_NAME = "MINTER_BURNER_ROLE";
    string constant ROUTER_SETUP_ROLE_NAME = "ROUTER_SETUP_ROLE";
    string constant ROUTER_ETH_VAULT_ROLE_NAME = "ROUTER_ETH_VAULT_ROLE";
    string constant ROUTER_LINK_VAULT_ROLE_NAME = "ROUTER_LINK_VAULT_ROLE";

    function getPoolSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory poolSelectors = new bytes4[](4);
        poolSelectors[0] = Pool.initCollateralAsset.selector;
        poolSelectors[1] = Pool.initDebtAsset.selector;
        poolSelectors[2] = Pool.setCollateralConfiguration.selector;
        poolSelectors[3] = Pool.setDebtConfiguration.selector;
        return poolSelectors;
    }

    function getSettingManagerSelectors()
        public
        pure
        returns (bytes4[] memory)
    {
        bytes4[] memory settingManagerSelectors = new bytes4[](18);
        settingManagerSelectors[0] = ProtocolSettingManager
            .initCollateralAsset
            .selector;
        settingManagerSelectors[1] = ProtocolSettingManager
            .initDebtAsset
            .selector;
        settingManagerSelectors[2] = ProtocolSettingManager
            .setCollateralConfiguration
            .selector;
        settingManagerSelectors[3] = ProtocolSettingManager
            .setCollateralLtv
            .selector;
        settingManagerSelectors[4] = ProtocolSettingManager
            .setCollateralLiquidationThreshold
            .selector;
        settingManagerSelectors[5] = ProtocolSettingManager
            .setCollateralLiquidationBonus
            .selector;
        settingManagerSelectors[6] = ProtocolSettingManager
            .setCollateralLiquidationProtocolFee
            .selector;
        settingManagerSelectors[9] = ProtocolSettingManager
            .setCollateralReserveFactor
            .selector;
        settingManagerSelectors[7] = ProtocolSettingManager
            .setCollateralSupplyCap
            .selector;
        settingManagerSelectors[8] = ProtocolSettingManager
            .setCollateralBorrowCap
            .selector;
        settingManagerSelectors[10] = ProtocolSettingManager
            .setDebtConfiguration
            .selector;
        settingManagerSelectors[11] = ProtocolSettingManager
            .setDebtSupplyCap
            .selector;
        settingManagerSelectors[12] = ProtocolSettingManager
            .setDebtBorrowCap
            .selector;
        settingManagerSelectors[13] = ProtocolSettingManager
            .setDebtReserveFactor
            .selector;
        settingManagerSelectors[14] = ProtocolSettingManager
            .freezeCollateral
            .selector;
        settingManagerSelectors[15] = ProtocolSettingManager
            .freezeDebt
            .selector;
        settingManagerSelectors[16] = ProtocolSettingManager
            .pauseCollateral
            .selector;
        settingManagerSelectors[17] = ProtocolSettingManager.pauseDebt.selector;

        return settingManagerSelectors;
    }

    function getVaultSetupSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory vaultSetupSelectors = new bytes4[](11);
        vaultSetupSelectors[0] = VaultETH.addStakingRouter.selector;
        vaultSetupSelectors[1] = VaultETH.removeStakingRouter.selector;
        vaultSetupSelectors[2] = VaultETH.updateCurrentStakingRouter.selector;
        vaultSetupSelectors[3] = VaultETH.updateCurrentUnstakingRouter.selector;
        vaultSetupSelectors[4] = VaultETH.rebalance.selector;
        vaultSetupSelectors[5] = VaultLINK.addStakingRouter.selector;
        vaultSetupSelectors[6] = VaultLINK.removeStakingRouter.selector;
        vaultSetupSelectors[7] = VaultLINK.updateCurrentStakingRouter.selector;
        vaultSetupSelectors[9] = VaultLINK
            .updateCurrentUnstakingRouter
            .selector;
        vaultSetupSelectors[10] = VaultLINK.rebalance.selector;
        return vaultSetupSelectors;
    }

    function getVaultLockCollateralSelectors()
        public
        pure
        returns (bytes4[] memory)
    {
        bytes4[] memory vaultLockCollateralSelectors = new bytes4[](3);
        vaultLockCollateralSelectors[0] = VaultETH.lockCollateral.selector;
        vaultLockCollateralSelectors[1] = VaultETH.unlockCollateral.selector;
        vaultLockCollateralSelectors[2] = VaultETH.rebalance.selector;
        return vaultLockCollateralSelectors;
    }

    function getMinterColTokenSelectors()
        public
        pure
        returns (bytes4[] memory)
    {
        bytes4[] memory minterColTokenSelectors = new bytes4[](2);
        minterColTokenSelectors[0] = ColToken.mint.selector;
        minterColTokenSelectors[1] = ColToken.burn.selector;
        return minterColTokenSelectors;
    }

    function getMinterColEURSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory minterColEURSelectors = new bytes4[](5);
        minterColEURSelectors[0] = ColEUR.mint.selector;
        minterColEURSelectors[1] = ColEUR.redeem.selector;
        minterColEURSelectors[2] = ColEUR.deposit.selector;
        minterColEURSelectors[3] = ColEUR.withdraw.selector;
        minterColEURSelectors[4] = ColEUR.transferTokenTo.selector;
        return minterColEURSelectors;
    }

    function getMinterDebtEURSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory minterDebtEURSelectors = new bytes4[](2);
        minterDebtEURSelectors[0] = DebtEUR.mint.selector;
        minterDebtEURSelectors[1] = DebtEUR.burn.selector;
        return minterDebtEURSelectors;
    }

    function getRouterSetupSelectors() public pure returns (bytes4[] memory) {}

    function getRouterETHVaultSelectors()
        public
        pure
        returns (bytes4[] memory)
    {
        bytes4[] memory routerETHVaultSelectors = new bytes4[](8);
        routerETHVaultSelectors[0] = StakingRouterETHLido.stake.selector;
        routerETHVaultSelectors[1] = StakingRouterETHLido.unstake.selector;
        routerETHVaultSelectors[2] = StakingRouterETHMorpho.stake.selector;
        routerETHVaultSelectors[3] = StakingRouterETHMorpho.unstake.selector;
        routerETHVaultSelectors[4] = StakingRouterETHEtherfi.stake.selector;
        routerETHVaultSelectors[5] = StakingRouterETHEtherfi.unstake.selector;
        routerETHVaultSelectors[6] = StakingRouterETHRocketPool.stake.selector;
        routerETHVaultSelectors[7] = StakingRouterETHRocketPool
            .unstake
            .selector;
        return routerETHVaultSelectors;
    }

    function getRouterLinkVaultSelectors()
        public
        pure
        returns (bytes4[] memory)
    {
        bytes4[] memory routerLinkVaultSelectors = new bytes4[](2);
        routerLinkVaultSelectors[0] = StakingRouterLINK.stake.selector;
        routerLinkVaultSelectors[1] = StakingRouterLINK.unstake.selector;
        return routerLinkVaultSelectors;
    }
}
