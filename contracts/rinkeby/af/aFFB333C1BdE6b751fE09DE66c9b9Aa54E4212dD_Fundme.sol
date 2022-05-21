//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract Fundme{
    AggregatorV3Interface public priceFeed;
    mapping(address => uint256) public addressToAmountFunded;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }


    function fund() public payable{
        addressToAmountFunded[msg.sender] += msg.value;

    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

     function getPrice() public view returns (uint256) {
        (/* roundId*/, 
        int256 answer,
        /*startedAt */ , 
        /* updateAt*/,
        /* answerdInRound*/ ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
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