// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IVaultLINK} from "../../interfaces/vault/IVaultLINK.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract VaultLINK is
    Initializable,
    AccessManagedUpgradeable,
    UUPSUpgradeable,
    IVaultLINK
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAuthority) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}
}
