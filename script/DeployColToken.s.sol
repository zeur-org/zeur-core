// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {ColToken} from "../src/pool/tokenization/ColToken.sol";

contract DeployColToken is Script {
    error DeployColToken__InitialAuthorityNotSet();
    error DeployColToken__NameNotSet();
    error DeployColToken__SymbolNotSet();

    function run() external {
        address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");
        string memory name = vm.envString("COLTOKEN_NAME");
        string memory symbol = vm.envString("COLTOKEN_SYMBOL");

        if (initialAuthority == address(0))
            revert DeployColToken__InitialAuthorityNotSet();

        if (bytes(name).length == 0) revert DeployColToken__NameNotSet();
        if (bytes(symbol).length == 0) revert DeployColToken__SymbolNotSet();

        vm.startBroadcast();

        address colTokenProxy = Upgrades.deployUUPSProxy(
            "ColToken.sol",
            abi.encodeWithSelector(
                ColToken.initialize.selector,
                initialAuthority,
                name,
                symbol
            )
        );

        console.log(
            "------------------- ColToken Deployment Info -------------------"
        );
        console.log("ColToken Proxy:", colTokenProxy);
        console.log("Initial Authority:", initialAuthority);
        console.log("Name:", name);
        console.log("Symbol:", symbol);

        vm.stopBroadcast();
    }
}
