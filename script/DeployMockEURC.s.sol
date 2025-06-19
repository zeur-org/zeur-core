// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {MockTokenEURC} from "../src/mock/MockTokenEURC.sol";

contract DeployMockEURC is Script {
    error DeployMockEURC__NameNotSet();
    error DeployMockEURC__SymbolNotSet();

    function run() external {
        string memory name = vm.envString("MOCK_EURC_NAME");
        string memory symbol = vm.envString("MOCK_EURC_SYMBOL");

        if (bytes(name).length == 0) revert DeployMockEURC__NameNotSet();
        if (bytes(symbol).length == 0) revert DeployMockEURC__SymbolNotSet();

        vm.startBroadcast();

        MockTokenEURC mockTokenEURC = new MockTokenEURC(name, symbol);

        console.log(
            "------------------- Mock EURC Deployment Info -------------------"
        );
        console.log("Mock EURC:", address(mockTokenEURC));
        console.log("Name:", name);
        console.log("Symbol:", symbol);

        vm.stopBroadcast();
    }
}
