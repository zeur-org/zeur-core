// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Pool} from "../src/pool/Pool.sol";

contract DeployPool is Script {
    error DeployPool__InitialAuthorityNotSet();
    error DeployPool__OracleManagerNotSet();

    address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");
    address oracleManager = vm.envAddress("ORACLE_MANAGER");

    function run() external {
        if (initialAuthority == address(0))
            revert DeployPool__InitialAuthorityNotSet();
        if (oracleManager == address(0))
            revert DeployPool__OracleManagerNotSet();

        vm.startBroadcast();

        address poolProxy = Upgrades.deployUUPSProxy(
            "Pool.sol",
            abi.encodeWithSelector(
                Pool.initialize.selector,
                initialAuthority,
                oracleManager
            )
        );

        console.log(
            "------------------- Pool Deployment Info -------------------"
        );
        console.log("Pool Proxy:", poolProxy);
        console.log("Initial Authority:", initialAuthority);
        console.log("Oracle Manager:", oracleManager);

        vm.stopBroadcast();
    }
}
