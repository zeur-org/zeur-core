// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {ChainlinkOracleManager} from "../src/chainlink/ChainlinkOracleManager.sol";

contract DeployChainlinkOracleManager is Script {
    error DeployChainlinkOracleManager__InitialAuthorityNotSet();

    function run() external {
        address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");

        if (initialAuthority == address(0))
            revert DeployChainlinkOracleManager__InitialAuthorityNotSet();

        vm.startBroadcast();

        ChainlinkOracleManager chainlinkOracleManager = new ChainlinkOracleManager(
                initialAuthority
            );

        console.log(
            "------------------- Chainlink Oracle Manager Deployment Info -------------------"
        );
        console.log(
            "Chainlink Oracle Manager:",
            address(chainlinkOracleManager)
        );
        console.log("Initial Authority:", initialAuthority);

        vm.stopBroadcast();
    }
}
