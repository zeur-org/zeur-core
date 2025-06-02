// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AccessManaged} from "openzeppelin-contracts/access/manager/AccessManaged.sol";
import {ERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ColEUR is ERC4626, AccessManaged {
    constructor(
        ERC20 asset,
        address initialAuthority
    )
        ERC20(asset.name(), asset.symbol())
        ERC4626(asset)
        AccessManaged(initialAuthority)
    {}
}
