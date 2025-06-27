// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Roles} from "../../src/helpers/Roles.sol";
import {ProtocolAccessManager} from "../../src/pool/manager/ProtocolAccessManager.sol";
import {ProtocolSettingManager} from "../../src/pool/manager/ProtocolSettingManager.sol";

contract SetupVaultRole is Script {
    error SetupVaultRole__VaultNotSet();
    error SetRoles__AccessManagerNotSet();

    function run() external {
        address vaultETHAddress = vm.envAddress("VAULT_ETH");
        address vaultLINKAddress = vm.envAddress("VAULT_LINK");
        address accessManagerAddress = vm.envAddress("ACCESS_MANAGER");
        address poolAddress = vm.envAddress("POOL");

        if (vaultETHAddress == address(0)) revert SetupVaultRole__VaultNotSet();
        if (vaultLINKAddress == address(0))
            revert SetupVaultRole__VaultNotSet();
        if (accessManagerAddress == address(0))
            revert SetRoles__AccessManagerNotSet();

        ProtocolAccessManager accessManager = ProtocolAccessManager(
            accessManagerAddress
        );

        bytes4[] memory vaultSelectors = Roles
            .getVaultLockCollateralSelectors();
        uint64 vaultRole = Roles.VAULT_LOCK_COLLATERAL_ROLE;

        bytes4[] memory vaultSetupSelectors = Roles.getVaultSetupSelectors();
        uint64 vaultSetupRole = Roles.VAULT_SETUP_ROLE;

        vm.startBroadcast();

        accessManager.setTargetFunctionRole(
            vaultETHAddress,
            vaultSelectors,
            vaultRole
        );

        accessManager.setTargetFunctionRole(
            vaultLINKAddress,
            vaultSelectors,
            vaultRole
        );

        accessManager.setTargetFunctionRole(
            vaultETHAddress,
            vaultSetupSelectors,
            vaultSetupRole
        );

        accessManager.setTargetFunctionRole(
            vaultLINKAddress,
            vaultSetupSelectors,
            vaultSetupRole
        );

        vm.stopBroadcast();
    }
}
