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

    function mint(
        uint256 shares,
        address receiver
    ) public override restricted returns (uint256) {
        return super.mint(shares, receiver);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override restricted returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public override restricted returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override restricted returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }
}
