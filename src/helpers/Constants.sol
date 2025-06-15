// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

uint256 constant ETHER_TO_WEI = 1e18;
uint256 constant HEALTH_FACTOR_BASE = 1e4; // 100%
uint256 constant PRICE_PRECISION = 1e8; // 10^8 as Chainlink /USD pair price feed base
uint256 constant BPS_BASE = 10000; // 100%
uint256 constant EURC_PRECISION = 1e6; // 6 decimals
uint256 constant EURI_PRECISION = 1e18; // 18 decimals
uint256 constant LINK_PRECISION = 1e18; // 18 decimals

address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant INITIAL_ADMIN = address(11);
address constant POOL_ADMIN = address(12);
address constant VAULT_ADMIN = address(13);
address constant SETTING_MANAGER_ADMIN = address(14);
