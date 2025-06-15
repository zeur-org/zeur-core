// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {ColEUR} from "../src/pool/tokenization/ColEUR.sol";

contract DeployColEUR is Script {
    error DeployColEUR__InitialAuthorityNotSet();
    error DeployColEUR__NameNotSet();
    error DeployColEUR__SymbolNotSet();

    function run() external {
        address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");
        address assetEUR = vm.envAddress("COLEUR_ASSET");
        string memory name = vm.envString("COLEUR_NAME");
        string memory symbol = vm.envString("COLEUR_SYMBOL");

        if (initialAuthority == address(0))
            revert DeployColEUR__InitialAuthorityNotSet();

        if (bytes(name).length == 0) revert DeployColEUR__NameNotSet();
        if (bytes(symbol).length == 0) revert DeployColEUR__SymbolNotSet();

        vm.startBroadcast();

        address colEURProxy = Upgrades.deployUUPSProxy(
            "ColEUR.sol",
            abi.encodeWithSelector(
                ColEUR.initialize.selector,
                initialAuthority,
                assetEUR,
                name,
                symbol
            )
        );

        console.log(
            "------------------- ColEUR Deployment Info -------------------"
        );
        console.log("ColEUR Proxy:", colEURProxy);
        console.log("Initial Authority:", initialAuthority);
        console.log("Asset:", assetEUR);
        console.log("Name:", name);
        console.log("Symbol:", symbol);

        vm.stopBroadcast();
    }
}
