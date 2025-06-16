// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StakingRouterLINK} from "../../src/pool/router/StakingRouterLINK.sol";

contract StakingRouterLINKV2 is StakingRouterLINK {
    function getVersion() public pure returns (uint256) {
        return 2;
    }
}
