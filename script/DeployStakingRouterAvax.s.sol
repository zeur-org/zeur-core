// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {StakingRouterAVAXBenqi} from "../src/pool/router/StakingRouterAVAXBenqi.sol";

contract DeployStakingRouterAvax is Script {
    error DeployStakingRouters__InitialAuthorityNotSet();
    error DeployStakingRouters__StAVAXNotSet();

    address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");
    address stAVAX = vm.envAddress("STAVAX");

    function run() external {
        if (initialAuthority == address(0))
            revert DeployStakingRouters__InitialAuthorityNotSet();

        if (stAVAX == address(0)) revert DeployStakingRouters__StAVAXNotSet();

        vm.startBroadcast();

        address stakingRouterAVAXBenqiProxy = Upgrades.deployUUPSProxy(
            "StakingRouterAVAXBenqi.sol",
            abi.encodeWithSelector(
                StakingRouterAVAXBenqi.initialize.selector,
                initialAuthority,
                stAVAX
            )
        );

        console.log(
            "------------------- Staking Routers Deployment Info -------------------"
        );
        console.log("Initial Authority:", initialAuthority);
        console.log(
            "Staking Router AVAX Benqi Proxy:",
            stakingRouterAVAXBenqiProxy
        );
        console.log("StAVAX:", stAVAX);

        vm.stopBroadcast();
    }
}
