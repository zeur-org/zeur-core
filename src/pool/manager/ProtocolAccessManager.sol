// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AccessManager} from "openzeppelin-contracts/access/manager/AccessManager.sol";

contract ProtocolAccessManager is AccessManager {
    constructor(address initialAdmin) AccessManager(initialAdmin) {}
}
