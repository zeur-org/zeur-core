// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {VaultETH} from "../src/pool/vault/VaultETH.sol";

contract DeployVaultETH is Script {
    error DeployVaultETH__InitialAuthorityNotSet();

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployerAddress = vm.addr(deployerPrivateKey);
    address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");

    function run() external {
        if (initialAuthority == address(0))
            revert DeployVaultETH__InitialAuthorityNotSet();

        vm.startBroadcast();

        address vaultETHProxy = Upgrades.deployUUPSProxy(
            "VaultETH.sol",
            abi.encodeWithSelector(
                VaultETH.initialize.selector,
                initialAuthority
            )
        );

        console.log(
            "------------------- VaultETH Deployment Info -------------------"
        );
        console.log("VaultETH Proxy:", vaultETHProxy);
        console.log("Initial Authority:", initialAuthority);

        vm.stopBroadcast();
    }
}
