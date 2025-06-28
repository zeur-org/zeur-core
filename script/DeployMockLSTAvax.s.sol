// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {MocksAVAX} from "../src/mock/MocksAVAX.sol";

contract DeployMockLSTAvax is Script {
    function run() external {
        vm.startBroadcast();

        MocksAVAX mockLSTAvax = new MocksAVAX();

        console.log(
            "------------------- Mock LSTAvax Deployment Info -------------------"
        );
        console.log("Mock LSTAvax:", address(mockLSTAvax));

        vm.stopBroadcast();
    }
}
