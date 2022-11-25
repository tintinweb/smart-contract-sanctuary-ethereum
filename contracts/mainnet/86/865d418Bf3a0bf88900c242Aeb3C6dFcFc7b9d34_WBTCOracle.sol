// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IChainlinkAggregatorV2V3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);
}

/// @notice Provides contract for fetching WBTC/ETH Chainlink price, using WBTC/BTC and BTC/ETH Chainlink oracles
contract WBTCOracle is IChainlinkAggregatorV2V3 {
    address public immutable WBTCBTCChainlinkAggregator;
    address public immutable BTCETHChainlinkAggregator;

    constructor(
        address _WBTCBTCChainlinkAggregator,
        address _BTCETHChainlinkAggregator
    ) {
        // WBTCBTCChainlinkAggregator = "0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23";
        // BTCETHChainlinkAggregator = "0xdeb288F737066589598e9214E782fa5A8eD689e8";

        WBTCBTCChainlinkAggregator = _WBTCBTCChainlinkAggregator;
        BTCETHChainlinkAggregator = _BTCETHChainlinkAggregator;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function description() external pure override returns (string memory) {
        return "WBTC / ETH";
    }

    /// @notice Get latest WBTC/BTC Chainlink feed timestamp
    /// @return timestamp latest WBTC/BTC Chainlink feed timestamp
    function latestTimestamp()
        external
        view
        override
        returns (uint256 timestamp)
    {
        return
            IChainlinkAggregatorV2V3(WBTCBTCChainlinkAggregator)
                .latestTimestamp();
    }

    /// @notice Get WBTC/ETH price. It does not check Chainlink oracles staleness! If staleness check needed, it's recommended to use latestTimestamp() functions on both Chainlink feeds used
    /// @return answer WBTC/ETH price or 0 if failure
    function latestAnswer() external view override returns (int256 answer) {
        // get the WBTC/BTC and BTC/ETH prices
        int256 WBTCBTCPrice = IChainlinkAggregatorV2V3(
            WBTCBTCChainlinkAggregator
        ).latestAnswer();
        int256 BTCETHPrice = IChainlinkAggregatorV2V3(BTCETHChainlinkAggregator)
            .latestAnswer();

        if (WBTCBTCPrice <= 0 || BTCETHPrice <= 0) return 0;

        // calculate WBTC/ETH price
        return (WBTCBTCPrice * BTCETHPrice) / 1e8;
    }
}