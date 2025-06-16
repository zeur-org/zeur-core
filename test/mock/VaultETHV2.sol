// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VaultETH} from "../../src/pool/vault/VaultETH.sol";

contract VaultETHV2 is VaultETH {
    function getVersion() public pure returns (uint256) {
        return 2;
    }
}
