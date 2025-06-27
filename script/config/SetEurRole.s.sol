// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Roles} from "../../src/helpers/Roles.sol";
import {ProtocolAccessManager} from "../../src/pool/manager/ProtocolAccessManager.sol";

contract SetEurRole is Script {
    using Roles for *;

    error SetEurRole__AccessManagerNotSet();
    error SetEurRole__PoolNotSet();

    function run() external {
        address accessManagerAddress = vm.envAddress("ACCESS_MANAGER");
        address colEURAddress = vm.envAddress("COLEUR_ADDRESS");
        address debtEURAddress = vm.envAddress("DEBTEUR_ADDRESS");
        address poolAddress = vm.envAddress("POOL");

        if (accessManagerAddress == address(0))
            revert SetEurRole__AccessManagerNotSet();

        ProtocolAccessManager accessManager = ProtocolAccessManager(
            accessManagerAddress
        );

        bytes4[] memory colEURSelectors = Roles.getMinterColEURSelectors();
        bytes4[] memory debtEURSelectors = Roles.getMinterDebtEURSelectors();

        uint64 minterBurnerRole = Roles.MINTER_BURNER_ROLE;

        vm.startBroadcast();
        accessManager.grantRole(minterBurnerRole, poolAddress, 0);

        // accessManager.setTargetFunctionRole(
        //     colEURAddress,
        //     colEURSelectors,
        //     minterBurnerRole
        // );

        // accessManager.setTargetFunctionRole(
        //     debtEURAddress,
        //     debtEURSelectors,
        //     minterBurnerRole
        // );

        vm.stopBroadcast();
    }
}
