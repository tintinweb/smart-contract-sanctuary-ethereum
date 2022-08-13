//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../venders/chainlink/AggregatorV3Interface.sol";

contract ChainLinkDataFeedGetter {
    ///@notice wrap chainlink dataFeed
    function latestRoundAnswer(AggregatorV3Interface dataFeed) external view returns (int256) {
        (, int256 answer, , uint256 updatedAt, ) = dataFeed.latestRoundData();
        // solhint-disable not-rely-on-time
        require(updatedAt + 24 hours >= block.timestamp, "bad data feed");
        return answer;
    }

    ///@notice When comparing to a constant, you need to zoom in decimals times
    function decimals(AggregatorV3Interface dataFeed) external view returns (uint8) {
        return dataFeed.decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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