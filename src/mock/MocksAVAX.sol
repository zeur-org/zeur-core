// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IsAVAX} from "../interfaces/lst/avax/IsAVAX.sol";

contract MocksAVAX is IsAVAX {
    string public constant name = "Staked AVAX";
    string public constant symbol = "sAVAX";
    uint8 public constant decimals = 18;

    uint256 public totalShares;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Submit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);

    function totalSupply() external view returns (uint256) {
        return totalShares;
    }

    function totalAssets() public view returns (uint256) {
        return address(this).balance;
    }

    function submit() public payable returns (uint256 shares) {
        uint256 assets = msg.value;
        require(assets > 0, "ZERO_ASSETS");

        if (totalShares == 0 || totalAssets() - assets == 0) {
            shares = assets;
        } else {
            shares = (assets * totalShares) / (totalAssets() - assets);
        }

        require(shares > 0, "ZERO_SHARES");

        balanceOf[msg.sender] += shares;
        totalShares += shares;

        emit Submit(msg.sender, assets, shares);
        emit Transfer(address(0), msg.sender, shares);
    }

    function withdraw(uint256 shares) public returns (uint256 assets) {
        require(
            shares > 0 && balanceOf[msg.sender] >= shares,
            "INVALID_SHARES"
        );

        assets = (shares * totalAssets()) / totalShares;

        balanceOf[msg.sender] -= shares;
        totalShares -= shares;

        (bool sent, ) = msg.sender.call{value: assets}("");
        require(sent, "TRANSFER_FAILED");

        emit Withdraw(msg.sender, assets, shares);
        emit Transfer(msg.sender, address(0), shares);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "BALANCE");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(balanceOf[from] >= amount, "BALANCE");
        require(allowance[from][msg.sender] >= amount, "ALLOWANCE");
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ZERO_ADDRESS");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    receive() external payable {
        submit();
    }
}
