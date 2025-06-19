// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Roles} from "../src/helpers/Roles.sol";
import {ProtocolAccessManager} from "../src/pool/manager/ProtocolAccessManager.sol";

contract SetPoolAdmin is Script {
    error SetPoolAdmin__AccessManagerNotSet();
    error SetPoolAdmin__PoolNotSet();

    function run() external {
        address poolAddress = vm.envAddress("POOL");
        address accessManagerAddress = vm.envAddress("ACCESS_MANAGER");

        if (accessManagerAddress == address(0))
            revert SetPoolAdmin__AccessManagerNotSet();
        if (poolAddress == address(0)) revert SetPoolAdmin__PoolNotSet();

        ProtocolAccessManager accessManager = ProtocolAccessManager(
            accessManagerAddress
        );

        bytes4[] memory poolSelectors = Roles.getPoolSelectors();
        uint64 poolAdminRole = Roles.POOL_INIT_RESERVE_ROLE;

        vm.startBroadcast();

        accessManager.setTargetFunctionRole(
            poolAddress,
            poolSelectors,
            poolAdminRole
        );

        vm.stopBroadcast();
    }
}
