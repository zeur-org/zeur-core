// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IChainlinkOracleManager {
    error ChainlinkOracleManager__InvalidPrice(address asset, int256 price);

    event ChainlinkOracleSet(address indexed asset, address indexed oracle);

    function setChainlinkOracle(address asset, address oracle) external;

    function getChainlinkOracle(address asset) external view returns (address);

    function getAssetPrice(address asset) external view returns (uint256);

    function getAssetsPrices(
        address[] calldata assets
    ) external view returns (uint256[] memory);
}
