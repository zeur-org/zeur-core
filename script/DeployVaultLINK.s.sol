// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {VaultLINK} from "../src/pool/vault/VaultLINK.sol";

contract DeployVaultLINK is Script {
    error DeployVaultLINK__InitialAuthorityNotSet();

    address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");
    address link = vm.envAddress("LINK_TOKEN");

    function run() external {
        if (initialAuthority == address(0))
            revert DeployVaultLINK__InitialAuthorityNotSet();

        vm.startBroadcast();

        address vaultLINKProxy = Upgrades.deployUUPSProxy(
            "VaultLINK.sol",
            abi.encodeWithSelector(
                VaultLINK.initialize.selector,
                initialAuthority,
                link
            )
        );

        console.log(
            "------------------- VaultLINK Deployment Info -------------------"
        );
        console.log("VaultLINK Proxy:", vaultLINKProxy);
        console.log("Initial Authority:", initialAuthority);
        console.log("Link:", link);

        vm.stopBroadcast();
    }
}
