//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ETH_Price{

    AggregatorV3Interface aV3i;

    constructor(address aV3i_Address){
        aV3i = AggregatorV3Interface(aV3i_Address);
    }

    function getPrice() public view returns(uint256){
        (,int256 price,,,) = aV3i.latestRoundData();
        return uint256(price);
    }

    function getVersion() public view returns(uint256){
        return aV3i.version();
    }
    function getDecimals() public view returns(uint256){
        return aV3i.decimals();
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