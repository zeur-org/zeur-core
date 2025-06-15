// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {StakingRouterETHLido} from "../src/pool/router/StakingRouterETHLido.sol";
import {StakingRouterETHEtherfi} from "../src/pool/router/StakingRouterETHEtherfi.sol";
import {StakingRouterETHRocketPool} from "../src/pool/router/StakingRouterETHRocketPool.sol";
import {StakingRouterETHMorpho} from "../src/pool/router/StakingRouterETHMorpho.sol";
import {StakingRouterLINK} from "../src/pool/router/StakingRouterLINK.sol";

contract DeployStakingRouters is Script {
    error DeployStakingRouters__InitialAuthorityNotSet();
    error DeployStakingRouters__LidoETHNotSet();
    error DeployStakingRouters__LidoWithdrawalQueueNotSet();
    error DeployStakingRouters__EtherfiETHNotSet();
    error DeployStakingRouters__EtherfiPoolNotSet();
    error DeployStakingRouters__RocketPoolETHNotSet();
    error DeployStakingRouters__RocketPoolPoolNotSet();
    error DeployStakingRouters__RocketPoolProtocolSettingNotSet();
    error DeployStakingRouters__MorphoETHNotSet();
    error DeployStakingRouters__MorphoPoolNotSet();
    error DeployStakingRouters__LINKNotSet(); // TODO: Add LINK token address

    address initialAuthority = vm.envAddress("INITIAL_AUTHORITY");
    address lidoStETH = vm.envAddress("LIDO_STETH");
    address lidoWithdrawQueue = vm.envAddress("LIDO_WITHDRAWQUEUE");

    address etherfiETH = vm.envAddress("ETHERFI_EETH");
    address etherfiPool = vm.envAddress("ETHERFI_POOL");

    address rocketRETH = vm.envAddress("ROCKET_RETH");
    address rocketPool = vm.envAddress("ROCKET_POOL");
    address rocketProtocolSetting = vm.envAddress("ROCKET_PROTOCOL_SETTING");

    address morphoETH = vm.envAddress("MORPHO_ETH");
    address morphoPool = vm.envAddress("MORPHO_POOL");

    address stLink = vm.envAddress("STAKELINK_STLINK");
    address link = vm.envAddress("LINK_TOKEN");
    address priorityPool = vm.envAddress("STAKELINK_PRIORITY_POOL");

    function run() external {
        if (initialAuthority == address(0))
            revert DeployStakingRouters__InitialAuthorityNotSet();

        vm.startBroadcast();

        address lidoRouterProxy = Upgrades.deployUUPSProxy(
            "StakingRouterETHLido.sol",
            abi.encodeWithSelector(
                StakingRouterETHLido.initialize.selector,
                initialAuthority,
                lidoStETH,
                lidoWithdrawQueue
            )
        );

        address etherfiRouterProxy = Upgrades.deployUUPSProxy(
            "StakingRouterETHEtherfi.sol",
            abi.encodeWithSelector(
                StakingRouterETHEtherfi.initialize.selector,
                initialAuthority
            )
        );

        address rocketRouterProxy = Upgrades.deployUUPSProxy(
            "StakingRouterETHRocketPool.sol",
            abi.encodeWithSelector(
                StakingRouterETHRocketPool.initialize.selector,
                initialAuthority,
                rocketRETH,
                rocketPool,
                rocketProtocolSetting
            )
        );

        address morphoRouterProxy = Upgrades.deployUUPSProxy(
            "StakingRouterETHMorpho.sol",
            abi.encodeWithSelector(
                StakingRouterETHMorpho.initialize.selector,
                initialAuthority,
                morphoETH,
                morphoPool
            )
        );

        address stakingRouterLINKProxy = Upgrades.deployUUPSProxy(
            "StakingRouterLINK.sol",
            abi.encodeWithSelector(
                StakingRouterLINK.initialize.selector,
                initialAuthority,
                stLink,
                link,
                priorityPool
            )
        );

        console.log(
            "------------------- Staking Routers Deployment Info -------------------"
        );
        console.log("Initial Authority:", initialAuthority);
        console.log("Lido Router Proxy:", lidoRouterProxy);
        console.log("Lido StETH:", lidoStETH);

        console.log("Etherfi Router Proxy:", etherfiRouterProxy);
        console.log("Etherfi ETH:", etherfiETH);
        console.log("Etherfi Pool:", etherfiPool);

        console.log("Rocket Router Proxy:", rocketRouterProxy);
        console.log("Rocket RETH:", rocketRETH);
        console.log("Rocket Pool:", rocketPool);
        console.log("Rocket Protocol Setting:", rocketProtocolSetting);

        console.log("Morpho Router Proxy:", morphoRouterProxy);
        console.log("Morpho ETH:", morphoETH);
        console.log("Morpho Pool:", morphoPool);

        console.log("Staking Router LINK Proxy:", stakingRouterLINKProxy);
        console.log("Staking Router LINK:", priorityPool);
        console.log("Staking Router LINK:", link);
        console.log("Staking Router LINK:", stLink);

        vm.stopBroadcast();
    }
}
