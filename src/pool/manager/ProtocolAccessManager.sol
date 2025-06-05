// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ProtocolAccessManager is
    Initializable,
    AccessManagerUpgradeable,
    UUPSUpgradeable
{
    error ProtocolAccessManager_NotAdmin();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAdmin) public override initializer {
        __AccessManager_init(initialAdmin);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override {
        (bool isMember, ) = hasRole(ADMIN_ROLE, msg.sender);
        if (!isMember) revert ProtocolAccessManager_NotAdmin();
    }
}
