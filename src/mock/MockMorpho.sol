// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockMorpho
 * @dev Simplified Morpho WETH vault mock for testing Morpho WETH vaults.
 *      Allows deposit of WETH to mint mWETH, withdrawal of mWETH for WETH
 */
contract MockMorpho is ERC4626 {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) ERC4626(ERC20(asset)) ERC20(name, symbol) {}
}

/**
 * @title MockWETH
 * @dev Simplified Wrapped Ether (WETH) mock for testing Morpho WETH vaults.
 *      Allows deposit of ETH to mint WETH, withdrawal of WETH for ETH,
 *      and a faucet for arbitrary minting during tests.
 */
contract MockWETH is ERC20 {
    constructor() ERC20("Mock Wrapped Ether", "WETH") {}

    /**
     * @dev Deposit ETH to mint WETH at a 1:1 ratio.
     */
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH to deposit");
        _mint(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw WETH to receive ETH at a 1:1 ratio.
     * @param wad Amount of WETH to burn
     */
    function withdraw(uint256 wad) public {
        require(balanceOf(msg.sender) >= wad, "Insufficient WETH balance");
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
    }

    /**
     * @dev Fallback function that allows receiving ETH directly and wrapping it.
     */
    receive() external payable {
        deposit();
    }

    /**
     * @dev Faucet function for tests: owner can mint arbitrary WETH.
     * @param to Recipient address
     * @param amount Amount of WETH to mint
     */
    function faucet(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
