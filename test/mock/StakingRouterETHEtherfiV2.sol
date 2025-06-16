// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StakingRouterETHEtherfi} from "../../src/pool/router/StakingRouterETHEtherfi.sol";

contract StakingRouterETHEtherfiV2 is StakingRouterETHEtherfi {
    function getVersion() public pure returns (uint256) {
        return 2;
    }
}
