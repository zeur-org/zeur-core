// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades, Options} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {ColEUR} from "../src/pool/tokenization/ColEUR.sol";

contract UpgradeColEUR is Script {
    address colEURProxy = vm.envAddress("COLEUR_ADDRESS");

    function run() external {
        // Build an Options struct that disables *all* validations
        Options memory opts;
        opts.unsafeSkipAllChecks = true;

        vm.startBroadcast();
        // Now perform the upgrade with zero checks
        Upgrades.upgradeProxy(
            colEURProxy,
            "ColEUR.sol:ColEUR", // path to your new implementation
            "", // no initialize call
            opts, // <-- skips all checks
            msg.sender // call as the proxy-admin
        );

        vm.stopBroadcast();
    }
}
