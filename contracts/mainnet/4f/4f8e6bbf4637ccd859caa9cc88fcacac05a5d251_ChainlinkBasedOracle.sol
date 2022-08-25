// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IChainlinkAggregatorV2V3 {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}

/// @notice Provides generic contract for fetching underlying/ETH Chainlink price, using underlying/USD and ETH/USD Chainlink oracles
contract ChainlinkBasedOracle is IChainlinkAggregatorV2V3 {
    address immutable public underlyingUSDChainlinkAggregator;
    address immutable public ETHUSDChainlinkAggregator;
    string desc;

    constructor(
        address _underlyingUSDChainlinkAggregator,
        address _ETHUSDChainlinkAggregator,
        string memory _description
    ) {
        underlyingUSDChainlinkAggregator = _underlyingUSDChainlinkAggregator;
        ETHUSDChainlinkAggregator = _ETHUSDChainlinkAggregator;
        desc = _description;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function description() external view override returns (string memory) {
        return desc;
    }

    /// @notice Get latest underlying/USD Chainlink feed timestamp
    /// @return timestamp latest underlying/USD Chainlink feed timestamp
    function latestTimestamp() external view override returns (uint256 timestamp) {
        return IChainlinkAggregatorV2V3(underlyingUSDChainlinkAggregator).latestTimestamp();
    }

    /// @notice Get underlying/ETH price. It does not check Chainlink oracles staleness! If staleness check needed, it's recommended to use latestTimestamp() functions on both Chainlink feeds used
    /// @return answer underlying/ETH price or 0 if failure
    function latestAnswer() external view override returns (int256 answer) {
        // get the ETH/USD and underlying/USD prices
        int256 ETHUSDPrice = IChainlinkAggregatorV2V3(ETHUSDChainlinkAggregator).latestAnswer();
        int256 underlyingUSDPrice = IChainlinkAggregatorV2V3(underlyingUSDChainlinkAggregator).latestAnswer();

        if (ETHUSDPrice <= 0 || underlyingUSDPrice <= 0) return 0;

        // calculate underlying/ETH price
        return underlyingUSDPrice * 1e18 / ETHUSDPrice;
    }
}