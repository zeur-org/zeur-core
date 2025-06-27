// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {MockRETH, MockRocketDepositPool, MockRocketDAOSettings} from "../src/mock/MockRocketPool.sol";

contract DeployMockLSTRocketPool is Script {
    function run() external {
        vm.startBroadcast();

        MockRETH rETH = new MockRETH();
        MockRocketDepositPool rocketDepositPool = new MockRocketDepositPool(
            address(rETH)
        );
        MockRocketDAOSettings rocketDAOSettings = new MockRocketDAOSettings();

        console.log(
            "------------------- Mock Rocket Pool Deployment Info -------------------"
        );
        console.log("Mock RETH:", address(rETH));
        console.log("Mock Rocket Deposit Pool:", address(rocketDepositPool));
        console.log("Mock Rocket DAO Settings:", address(rocketDAOSettings));

        vm.stopBroadcast();
    }
}
