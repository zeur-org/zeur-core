// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {MockTokenLINK} from "../src/mock/MockTokenLINK.sol";

contract DeployMockLINK is Script {
    error DeployMockLINK__NameNotSet();
    error DeployMockLINK__SymbolNotSet();

    function run() external {
        string memory name = vm.envString("MOCK_LINK_NAME");
        string memory symbol = vm.envString("MOCK_LINK_SYMBOL");

        if (bytes(name).length == 0) revert DeployMockLINK__NameNotSet();
        if (bytes(symbol).length == 0) revert DeployMockLINK__SymbolNotSet();

        vm.startBroadcast();

        MockTokenLINK mockTokenLINK = new MockTokenLINK(name, symbol);

        console.log(
            "------------------- Mock LINK Deployment Info -------------------"
        );
        console.log("Mock LINK:", address(mockTokenLINK));
        console.log("Name:", name);
        console.log("Symbol:", symbol);

        vm.stopBroadcast();
    }
}
