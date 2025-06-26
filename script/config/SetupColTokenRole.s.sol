// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Roles} from "../../src/helpers/Roles.sol";
import {ProtocolAccessManager} from "../../src/pool/manager/ProtocolAccessManager.sol";

contract SetupColTokenRole is Script {
    using Roles for *;

    error SetupColTokenRole__AccessManagerNotSet();
    error SetupColTokenRole__PoolNotSet();

    function run() external {
        address accessManagerAddress = vm.envAddress("ACCESS_MANAGER");
        address colTokenETHAddress = vm.envAddress("COLTOKEN_ETH");
        address colTokenLINKAddress = vm.envAddress("COLTOKEN_LINK");

        if (accessManagerAddress == address(0))
            revert SetupColTokenRole__AccessManagerNotSet();

        ProtocolAccessManager accessManager = ProtocolAccessManager(
            accessManagerAddress
        );

        bytes4[] memory colTokenSelectors = Roles.getMinterColTokenSelectors();

        uint64 colTokenRole = Roles.MINTER_BURNER_ROLE;

        vm.startBroadcast();
        accessManager.setTargetFunctionRole(
            colTokenETHAddress,
            colTokenSelectors,
            colTokenRole
        );

        accessManager.setTargetFunctionRole(
            colTokenLINKAddress,
            colTokenSelectors,
            colTokenRole
        );
        vm.stopBroadcast();
    }
}
