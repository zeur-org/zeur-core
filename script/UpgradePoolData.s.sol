// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades, Options} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {PoolData} from "../src/pool/PoolData.sol";

contract UpgradePoolData is Script {
    address poolDataProxy = vm.envAddress("POOL_DATA_PROXY");

    function run() external {
        vm.startBroadcast();

        // Build an Options struct that disables *all* validations
        Options memory opts;
        opts.unsafeSkipAllChecks = true;

        // Now perform the upgrade with zero checks
        Upgrades.upgradeProxy(
            poolDataProxy,
            "PoolData.sol:PoolData", // path to your new implementation
            "", // no initialize call
            opts, // <-- skips all checks
            msg.sender // call as the proxy-admin
        );

        vm.stopBroadcast();
    }
}
