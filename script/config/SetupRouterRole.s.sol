// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Roles} from "../../src/helpers/Roles.sol";
import {ProtocolAccessManager} from "../../src/pool/manager/ProtocolAccessManager.sol";
import {ProtocolSettingManager} from "../../src/pool/manager/ProtocolSettingManager.sol";

contract SetupRouterRole is Script {
    error SetupRouterRole__RouterNotSet();
    error SetRoles__AccessManagerNotSet();

    function run() external {
        address routerLidoAddress = vm.envAddress("ROUTER_LIDO");
        address routerMorphoAddress = vm.envAddress("ROUTER_MORPHO");
        address routerEtherfiAddress = vm.envAddress("ROUTER_ETHERFI");
        address routerRocketPoolAddress = vm.envAddress("ROUTER_ROCKETPOOL");
        address routerLINKAddress = vm.envAddress("ROUTER_LINK");
        address accessManagerAddress = vm.envAddress("ACCESS_MANAGER");

        if (routerLidoAddress == address(0))
            revert SetupRouterRole__RouterNotSet();
        if (routerMorphoAddress == address(0))
            revert SetupRouterRole__RouterNotSet();
        if (routerEtherfiAddress == address(0))
            revert SetupRouterRole__RouterNotSet();
        if (routerRocketPoolAddress == address(0))
            revert SetupRouterRole__RouterNotSet();
        if (routerLINKAddress == address(0))
            revert SetupRouterRole__RouterNotSet();
        if (accessManagerAddress == address(0))
            revert SetRoles__AccessManagerNotSet();

        ProtocolAccessManager accessManager = ProtocolAccessManager(
            accessManagerAddress
        );

        bytes4[] memory routerETHSelectors = Roles.getRouterETHVaultSelectors();
        uint64 routerETHRole = Roles.ROUTER_ETH_VAULT_ROLE;

        bytes4[] memory routerLINKSelectors = Roles
            .getRouterLinkVaultSelectors();
        uint64 routerLINKRole = Roles.ROUTER_LINK_VAULT_ROLE;

        vm.startBroadcast();

        accessManager.setTargetFunctionRole(
            routerLidoAddress,
            routerETHSelectors,
            routerETHRole
        );

        accessManager.setTargetFunctionRole(
            routerMorphoAddress,
            routerETHSelectors,
            routerETHRole
        );

        accessManager.setTargetFunctionRole(
            routerEtherfiAddress,
            routerETHSelectors,
            routerETHRole
        );

        accessManager.setTargetFunctionRole(
            routerRocketPoolAddress,
            routerETHSelectors,
            routerETHRole
        );

        accessManager.setTargetFunctionRole(
            routerLINKAddress,
            routerLINKSelectors,
            routerLINKRole
        );

        vm.stopBroadcast();
    }
}
