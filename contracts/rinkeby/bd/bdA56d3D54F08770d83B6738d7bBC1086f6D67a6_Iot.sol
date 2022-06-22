// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./EthInUsd.sol";

error Iot__NotOwner();

contract Iot {
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    struct stats {
        int256 temperature;
        int256 humidity;
        int256 moisture;
    }

    stats iotReading;

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Iot__NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function updateIot(
        int256 _temperature,
        int256 _humidity,
        int256 _moisture
    ) public onlyOwner {
        iotReading = stats(_temperature, _humidity, _moisture);
    }

    function readStats() public view returns (stats memory) {
        return iotReading;
    }

    function getUsd() public view returns (uint256) {
        return EthInUsd.getCurrentPrice(priceFeed);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library EthInUsd {
    function getCurrentPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }
}