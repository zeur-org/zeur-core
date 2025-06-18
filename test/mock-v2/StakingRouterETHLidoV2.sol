// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StakingRouterETHLido} from "../../src/pool/router/StakingRouterETHLido.sol";

contract StakingRouterETHLidoV2 is StakingRouterETHLido {
    function getVersion() public pure returns (uint256) {
        return 2;
    }
}
