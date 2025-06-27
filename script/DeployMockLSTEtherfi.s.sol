// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {MockEETH, MockLiquidityPool} from "../src/mock/MockEtherfi.sol";

contract DeployMockLSTEtherfi is Script {
    function run() external {
        vm.startBroadcast();

        MockEETH mockEETH = new MockEETH();
        MockLiquidityPool mockLiquidityPool = new MockLiquidityPool(
            address(mockEETH)
        );

        console.log(
            "------------------- Mock LSTEtherfi Deployment Info -------------------"
        );
        console.log("Mock EETH:", address(mockEETH));
        console.log("Mock Liquidity Pool:", address(mockLiquidityPool));

        vm.stopBroadcast();
    }
}
