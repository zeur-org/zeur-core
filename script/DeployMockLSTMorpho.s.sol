// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {MockMorpho, MockWETH} from "../src/mock/MockMorpho.sol";

contract DeployMockLSTMorpho is Script {
    function run() external {
        vm.startBroadcast();

        MockWETH mockWETH = new MockWETH();
        address mockWETHAddress = address(mockWETH);

        MockMorpho mockMorpho = new MockMorpho(
            "Morpho WETH",
            "mWETH",
            mockWETHAddress
        );

        address mockMorphoAddress = address(mockMorpho);

        console.log(
            "------------------- Mock Morpho Deployment Info -------------------"
        );
        console.log("Mock Morpho:", mockMorphoAddress);
        console.log("Mock WETH:", mockWETHAddress);

        vm.stopBroadcast();
    }
}
