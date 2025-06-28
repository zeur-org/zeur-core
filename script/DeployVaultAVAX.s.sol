// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {VaultAVAX} from "../src/pool/vault/VaultAVAX.sol";

contract DeployVaultAVAX is Script {
    error DeployVaultAVAX__InitialAuthorityNotSet();

    address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");

    function run() external {
        if (initialAuthority == address(0))
            revert DeployVaultAVAX__InitialAuthorityNotSet();

        vm.startBroadcast();

        address vaultAVAXProxy = Upgrades.deployUUPSProxy(
            "VaultAVAX.sol",
            abi.encodeWithSelector(
                VaultAVAX.initialize.selector,
                initialAuthority
            )
        );

        console.log(
            "------------------- VaultAVAX Deployment Info -------------------"
        );
        console.log("VaultAVAX Proxy:", vaultAVAXProxy);
        console.log("Initial Authority:", initialAuthority);

        vm.stopBroadcast();
    }
}
