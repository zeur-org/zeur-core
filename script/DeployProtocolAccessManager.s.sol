// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {ProtocolAccessManager} from "../src/pool/manager/ProtocolAccessManager.sol";

contract DeployProtocolAccessManager is Script {
    error DeployProtocolAccessManager__InitialAdminNotSet();

    address initialAdmin = vm.envAddress("INITIAL_ADMIN");

    function run() external {
        if (initialAdmin == address(0))
            revert DeployProtocolAccessManager__InitialAdminNotSet();

        vm.startBroadcast();

        address protocolAccessManagerProxy = Upgrades.deployUUPSProxy(
            "ProtocolAccessManager.sol",
            abi.encodeWithSelector(
                ProtocolAccessManager.initialize.selector,
                initialAdmin
            )
        );

        console.log(
            "------------------- Protocol Access Manager Deployment Info -------------------"
        );
        console.log(
            "Protocol Access Manager Proxy:",
            protocolAccessManagerProxy
        );
        console.log("Initial Admin:", initialAdmin);

        vm.stopBroadcast();
    }
}
