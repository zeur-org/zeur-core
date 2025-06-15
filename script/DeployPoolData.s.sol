// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {PoolData} from "../src/pool/PoolData.sol";

contract DeployPoolData is Script {
    error DeployPoolData__InitialAuthorityNotSet();
    error DeployPoolData__OracleManagerNotSet();

    address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");
    address oracleManager = vm.envAddress("ORACLE_MANAGER");
    address pool = vm.envAddress("POOL");

    function run() external {
        if (initialAuthority == address(0))
            revert DeployPoolData__InitialAuthorityNotSet();
        if (oracleManager == address(0))
            revert DeployPoolData__OracleManagerNotSet();

        vm.startBroadcast();

        address poolDataProxy = Upgrades.deployUUPSProxy(
            "PoolData.sol",
            abi.encodeWithSelector(
                PoolData.initialize.selector,
                initialAuthority,
                pool,
                oracleManager
            )
        );

        console.log(
            "------------------- Pool Data Deployment Info -------------------"
        );
        console.log("Pool Data Proxy:", poolDataProxy);
        console.log("Initial Authority:", initialAuthority);
        console.log("Oracle Manager:", oracleManager);

        vm.stopBroadcast();
    }
}
