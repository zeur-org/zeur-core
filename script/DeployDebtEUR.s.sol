// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {DebtEUR} from "../src/pool/tokenization/DebtEUR.sol";

contract DeployDebtEUR is Script {
    error DeployDebtEUR__InitialAuthorityNotSet();
    error DeployDebtEUR__NameNotSet();
    error DeployDebtEUR__SymbolNotSet();

    function run() external {
        address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");
        string memory name = vm.envString("DEBTEUR_NAME");
        string memory symbol = vm.envString("DEBTEUR_SYMBOL");

        if (initialAuthority == address(0))
            revert DeployDebtEUR__InitialAuthorityNotSet();
        if (bytes(name).length == 0) revert DeployDebtEUR__NameNotSet();
        if (bytes(symbol).length == 0) revert DeployDebtEUR__SymbolNotSet();

        vm.startBroadcast();

        address debtEURProxy = Upgrades.deployUUPSProxy(
            "DebtEUR.sol",
            abi.encodeWithSelector(
                DebtEUR.initialize.selector,
                initialAuthority,
                name,
                symbol
            )
        );

        console.log(
            "------------------- DebtEUR Deployment Info -------------------"
        );
        console.log("DebtEUR Proxy:", debtEURProxy);
        console.log("Initial Authority:", initialAuthority);
        console.log("Name:", name);
        console.log("Symbol:", symbol);

        vm.stopBroadcast();
    }
}
