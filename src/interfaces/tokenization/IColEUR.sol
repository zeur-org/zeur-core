// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IColEUR is IERC4626 {
    function transferTokenTo(address to, uint256 amount) external;
}
