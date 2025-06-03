// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {IChainlinkOracleManager} from "../interfaces/chainlink/IChainlinkOracleManager.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract ChainlinkOracleManager is AccessManaged, IChainlinkOracleManager {
    using EnumerableMap for EnumerableMap.AddressToAddressMap;

    struct ChainlinkOracleManagerStorage {
        EnumerableMap.AddressToAddressMap _chainlinkOracles;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.ChainlinkOracleManager")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ChainlinkOracleManagerStorageLocation =
        0xccec2c79c4a9bc9dd271998b2adbeadfcde652e6f96e97f2c758e7f3bdf7b500;

    function _getChainlinkOracleManagerStorage()
        private
        pure
        returns (ChainlinkOracleManagerStorage storage $)
    {
        assembly {
            $.slot := ChainlinkOracleManagerStorageLocation
        }
    }

    constructor(address initialAuthority) AccessManaged(initialAuthority) {}

    function setChainlinkOracle(
        address asset,
        address oracle
    ) external override {
        ChainlinkOracleManagerStorage
            storage $ = _getChainlinkOracleManagerStorage();

        $._chainlinkOracles.set(asset, oracle);

        emit ChainlinkOracleSet(asset, oracle);
    }

    function getChainlinkOracle(
        address asset
    ) external view override returns (address) {
        ChainlinkOracleManagerStorage
            storage $ = _getChainlinkOracleManagerStorage();

        return $._chainlinkOracles.get(asset);
    }

    function getAssetPrice(
        address asset
    ) external view override returns (uint256) {
        ChainlinkOracleManagerStorage
            storage $ = _getChainlinkOracleManagerStorage();

        AggregatorV3Interface dataFeed = AggregatorV3Interface(
            $._chainlinkOracles.get(asset)
        );

        (
            ,
            /* uint80 roundId */ int256 answer /*uint256 startedAt*/ /*uint256 updatedAt*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = dataFeed.latestRoundData();

        if (answer <= 0)
            revert ChainlinkOracleManager__InvalidPrice(asset, answer);

        return uint256(answer);
    }

    function getAssetsPrices(
        address[] calldata assets
    ) external view override returns (uint256[] memory) {
        ChainlinkOracleManagerStorage
            storage $ = _getChainlinkOracleManagerStorage();

        uint256 length = assets.length;
        uint256[] memory prices = new uint256[](length);

        AggregatorV3Interface dataFeed;

        for (uint256 i = 0; i < length; i++) {
            dataFeed = AggregatorV3Interface(
                $._chainlinkOracles.get(assets[i])
            );

            (, int256 answer, , , ) = dataFeed.latestRoundData();

            if (answer <= 0)
                revert ChainlinkOracleManager__InvalidPrice(assets[i], answer);

            prices[i] = uint256(answer);
        }

        return prices;
    }
}
