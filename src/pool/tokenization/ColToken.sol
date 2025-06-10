// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ColToken is
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    AccessManagedUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        string memory name,
        string memory symbol
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function mint(address to, uint256 amount) external restricted {
        _mint(to, amount);
    }

    function burn(address account, uint256 value) external restricted {
        _burn(account, value);
    }

    // For v0, this is to prevent users from transferring colToken to other addresses
    // For v1, we will add a validateTransfer logic based on user's health factor to allow user's transfer
    function transfer(
        address to,
        uint256 value
    ) public override restricted returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override restricted returns (bool) {
        return super.transferFrom(from, to, value);
    }
}
