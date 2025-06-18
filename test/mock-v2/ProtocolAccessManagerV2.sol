// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ProtocolAccessManager} from "../../src/pool/manager/ProtocolAccessManager.sol";

contract ProtocolAccessManagerV2 is ProtocolAccessManager {
    function getVersion() public pure returns (uint256) {
        return 2;
    }
}
