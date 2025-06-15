// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {ProtocolSettingManager} from "../src/pool/manager/ProtocolSettingManager.sol";

contract DeployProtocolSettingManager is Script {
    error DeployProtocolSettingManager__InitialAuthorityNotSet();
    error DeployProtocolSettingManager__PoolNotSet();

    address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");
    address pool = vm.envAddress("POOL");

    function run() external {
        if (initialAuthority == address(0))
            revert DeployProtocolSettingManager__InitialAuthorityNotSet();
        if (pool == address(0))
            revert DeployProtocolSettingManager__PoolNotSet();

        vm.startBroadcast();

        address protocolSettingManagerProxy = Upgrades.deployUUPSProxy(
            "ProtocolSettingManager.sol",
            abi.encodeWithSelector(
                ProtocolSettingManager.initialize.selector,
                initialAuthority,
                pool
            )
        );

        console.log(
            "------------------- Protocol Setting Manager Deployment Info -------------------"
        );
        console.log(
            "Protocol Setting Manager Proxy:",
            protocolSettingManagerProxy
        );
        console.log("Initial Authority:", initialAuthority);
        console.log("Pool:", pool);

        vm.stopBroadcast();
    }
}
