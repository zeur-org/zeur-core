// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StakingRouterETHRocketPool} from "../../src/pool/router/StakingRouterETHRocketPool.sol";

contract StakingRouterETHRocketPoolV2 is StakingRouterETHRocketPool {
    function getVersion() public pure returns (uint256) {
        return 2;
    }
}
