// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Roles} from "../../src/helpers/Roles.sol";
import {MockTokenEURC} from "../../src/mock/MockTokenEURC.sol";
import {Pool} from "../../src/pool/Pool.sol";

contract SetMintApprove is Script {
    using Roles for *;

    error SetMintApprove__MockTokenEURCNotSet();

    function run() external {
        address userAddress = vm.envAddress("USER_ADDRESS");
        address mockTokenEURCAddress = vm.envAddress("EURC_ADDRESS");
        address poolAddress = vm.envAddress("POOL_PROXY");

        if (mockTokenEURCAddress == address(0))
            revert SetMintApprove__MockTokenEURCNotSet();

        Pool pool = Pool(poolAddress);
        MockTokenEURC mockTokenEURC = MockTokenEURC(mockTokenEURCAddress);

        vm.startBroadcast();
        pool.supply(mockTokenEURCAddress, 2000000000, userAddress);
        // mockTokenEURC.mint(userAddress, 10000000000);
        // mockTokenEURC.approve(poolAddress, 10000000000);
        vm.stopBroadcast();
    }
}
