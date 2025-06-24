// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {MockLido, MockWithdrawalQueue} from "../../src/mock/MockLido.sol";

contract DeployMockLSTLido is Script {
    function run() external {
        vm.startBroadcast();

        MockLido mockLido = new MockLido();
        MockWithdrawalQueue mockWithdrawalQueue = new MockWithdrawalQueue(
            address(mockLido)
        );

        console.log(
            "------------------- Mock Lido Deployment Info -------------------"
        );
        console.log("Mock Lido:", address(mockLido));
        console.log("Mock Withdrawal Queue:", address(mockWithdrawalQueue));

        vm.stopBroadcast();
    }
}
