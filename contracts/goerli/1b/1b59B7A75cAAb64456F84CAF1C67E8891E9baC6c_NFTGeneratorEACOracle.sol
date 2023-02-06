// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./INFTGeneratorOracle.sol";

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

}

contract NFTGeneratorEACOracle is INFTGeneratorOracle {
    AggregatorV3Interface immutable aggregator;
    constructor(AggregatorV3Interface _aggregator){
        aggregator = _aggregator;
    }

    // @dev returns ETH/USD rate based on USD
    function getCurrentRate() external view returns (uint256) {
        (,int256 answer,,,) = aggregator.latestRoundData();
        return 10 ** 8 / uint256(answer);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INFTGeneratorOracle {
   function getCurrentRate() external view returns(uint256);
}