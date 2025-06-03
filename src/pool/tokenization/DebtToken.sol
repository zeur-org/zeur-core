// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract DebtToken is ERC20, ERC20Permit, AccessManaged {
    constructor(
        string memory name,
        string memory symbol,
        address initialAuthority
    ) ERC20(name, symbol) AccessManaged(initialAuthority) ERC20Permit(name) {}

    function mint(address to, uint256 amount) external restricted {
        _mint(to, amount);
    }

    function burn(address account, uint256 value) external restricted {
        _burn(account, value);
    }
}
