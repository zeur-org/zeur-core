// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ProtocolSettingManager} from "../../src/pool/manager/ProtocolSettingManager.sol";

contract ProtocolSettingManagerV2 is ProtocolSettingManager {
    function getVersion() public pure returns (uint256) {
        return 2;
    }
}
