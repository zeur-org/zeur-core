// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {MockstLINK, MockPriorityPool} from "../src/mock/MockStakeLink.sol";

contract DeployMockLSTStakeLink is Script {
    error DeployMockLSTStakeLink__LinkTokenNotSet();

    address linkToken = vm.envAddress("LINK_TOKEN");

    function run() external {
        vm.startBroadcast();

        if (linkToken == address(0))
            revert DeployMockLSTStakeLink__LinkTokenNotSet();

        MockstLINK stLinkToken = new MockstLINK(linkToken);
        MockPriorityPool linkPriorityPool = new MockPriorityPool(
            linkToken,
            address(stLinkToken)
        );

        console.log(
            "------------------- Mock Stake.Link Deployment Info -------------------"
        );
        console.log("Mock stLINK:", address(stLinkToken));
        console.log("Mock Priority Pool:", address(linkPriorityPool));

        vm.stopBroadcast();
    }
}
