// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VaultLINK} from "../../src/pool/vault/VaultLINK.sol";

contract VaultLINKV2 is VaultLINK {
    function getVersion() public pure returns (uint256) {
        return 2;
    }
}
