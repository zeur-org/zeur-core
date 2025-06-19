// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Roles} from "../../src/helpers/Roles.sol";
import {ProtocolAccessManager} from "../../src/pool/manager/ProtocolAccessManager.sol";
import {ProtocolSettingManager} from "../../src/pool/manager/ProtocolSettingManager.sol";

contract SetRoles is Script {
    error SetRoles__SettingManagerAdminNotSet();
    error SetRoles__PoolNotSet();
    error SetRoles__SettingManagerNotSet();
    error SetRoles__AccessManagerNotSet();

    function run() external {
        address settingManagerAdmin = vm.envAddress("SETTING_MANAGER_ADMIN");
        address poolAddress = vm.envAddress("POOL");
        address accessManagerAddress = vm.envAddress("ACCESS_MANAGER");
        address settingManagerAddress = vm.envAddress("SETTING_MANAGER");

        if (settingManagerAdmin == address(0))
            revert SetRoles__SettingManagerAdminNotSet();
        if (poolAddress == address(0)) revert SetRoles__PoolNotSet();
        if (accessManagerAddress == address(0))
            revert SetRoles__AccessManagerNotSet();
        if (settingManagerAddress == address(0))
            revert SetRoles__SettingManagerNotSet();

        ProtocolAccessManager accessManager = ProtocolAccessManager(
            accessManagerAddress
        );

        bytes4[] memory settingManagerSelectors = Roles
            .getSettingManagerSelectors();
        uint64 settingManagerAdminRole = Roles.SETTING_MANAGER_ADMIN_ROLE;

        vm.startBroadcast();

        accessManager.setTargetFunctionRole(
            settingManagerAddress,
            settingManagerSelectors,
            settingManagerAdminRole
        );

        vm.stopBroadcast();
    }
}
