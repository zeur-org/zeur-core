// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockTokenEURC is ERC20 {
    constructor() ERC20("Euro Coin", "EURC") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
