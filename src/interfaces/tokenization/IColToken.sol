// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IColToken {
    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 value) external;
}
