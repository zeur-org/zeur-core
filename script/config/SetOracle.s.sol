// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Roles} from "../../src/helpers/Roles.sol";
import {ChainlinkOracleManager} from "../../src/chainlink/ChainlinkOracleManager.sol";
import {ProtocolAccessManager} from "../../src/pool/manager/ProtocolAccessManager.sol";

contract SetOracle is Script {
    using Roles for *;

    error SetOracle__ChainlinkOracleManagerNotSet();

    function run() external {
        address accessManagerAddress = vm.envAddress("ACCESS_MANAGER");
        address chainlinkOracleManagerAddress = vm.envAddress("ORACLE_MANAGER");
        address initialAdmin = vm.envAddress("INITIAL_ADMIN");
        address eurAddress = vm.envAddress("EURC_TOKEN");
        address linkAddress = vm.envAddress("LINK_TOKEN");
        address ethAddress = vm.envAddress("ETH_TOKEN");
        address eurUSDAddress = vm.envAddress("EURUSD");
        address linkUSDAddress = vm.envAddress("LINKUSD");
        address ethUSDAddress = vm.envAddress("ETHUSD");

        if (chainlinkOracleManagerAddress == address(0))
            revert SetOracle__ChainlinkOracleManagerNotSet();

        ProtocolAccessManager accessManager = ProtocolAccessManager(
            accessManagerAddress
        );

        ChainlinkOracleManager chainlinkOracleManager = ChainlinkOracleManager(
            chainlinkOracleManagerAddress
        );

        bytes4[] memory oracleSetupSelectors = Roles.getOracleSetupSelectors();
        uint64 oracleSetupRole = Roles.ORACLE_SETUP_ROLE;

        vm.startBroadcast();
        // accessManager.setTargetFunctionRole(
        //     chainlinkOracleManagerAddress,
        //     oracleSetupSelectors,
        //     oracleSetupRole
        // );

        // accessManager.grantRole(oracleSetupRole, initialAdmin, 0);

        chainlinkOracleManager.setChainlinkOracle(eurAddress, eurUSDAddress);
        chainlinkOracleManager.setChainlinkOracle(linkAddress, linkUSDAddress);
        chainlinkOracleManager.setChainlinkOracle(ethAddress, ethUSDAddress);
        vm.stopBroadcast();
    }
}
