// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ProtocolVaultManager} from "../../src/pool/manager/ProtocolVaultManager.sol";

contract ProtocolVaultManagerV2 is ProtocolVaultManager {
    function getVersion() public pure returns (uint256) {
        return 2;
    }
}
