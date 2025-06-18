// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StakingRouterETHMorpho} from "../../src/pool/router/StakingRouterETHMorpho.sol";

contract StakingRouterETHMorphoV2 is StakingRouterETHMorpho {
    function getVersion() public pure returns (uint256) {
        return 2;
    }
}
