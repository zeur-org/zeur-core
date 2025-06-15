// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract DebtEUR is
    ERC20Upgradeable,
    AccessManagedUpgradeable,
    UUPSUpgradeable
{
    error DebtEUR_OperationNotAllowed();

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

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        revert DebtEUR_OperationNotAllowed();
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        revert DebtEUR_OperationNotAllowed();
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        revert DebtEUR_OperationNotAllowed();
    }

    function decimals() public view override(ERC20Upgradeable) returns (uint8) {
        return 6; // DebtEUR has 6 decimals
    }
}
