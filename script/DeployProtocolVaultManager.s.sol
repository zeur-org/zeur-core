// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {ProtocolVaultManager} from "../src/pool/manager/ProtocolVaultManager.sol";

contract DeployProtocolVaultManager is Script {
    error DeployProtocolVaultManager__InitialAuthorityNotSet();
    error DeployProtocolVaultManager__PoolNotSet();

    address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");
    address pool = vm.envAddress("POOL");

    function run() external {
        if (initialAuthority == address(0))
            revert DeployProtocolVaultManager__InitialAuthorityNotSet();
        if (pool == address(0)) revert DeployProtocolVaultManager__PoolNotSet();

        vm.startBroadcast();

        address protocolVaultManagerProxy = Upgrades.deployUUPSProxy(
            "ProtocolVaultManager.sol",
            abi.encodeWithSelector(
                ProtocolVaultManager.initialize.selector,
                initialAuthority,
                pool
            )
        );

        console.log(
            "------------------- Protocol Vault Manager Deployment Info -------------------"
        );
        console.log("Protocol Vault Manager Proxy:", protocolVaultManagerProxy);
        console.log("Initial Authority:", initialAuthority);
        console.log("Pool:", pool);

        vm.stopBroadcast();
    }
}
