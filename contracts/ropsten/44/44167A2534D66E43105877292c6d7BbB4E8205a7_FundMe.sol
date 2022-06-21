// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "AggregatorV3Interface.sol";

contract FundMe {

    AggregatorV3Interface public priceFeed;
    mapping(address => uint256) public addToAmnt;
    address public owner;

    constructor() public {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        owner = msg.sender;
    }

    function getV() public view returns (uint256){
        return priceFeed.version();
    }

    function fund() public payable {

        // uint256 minUsd = 50 * 10 ** 18;
        // require(getEthPrice(msg.value) >= minUsd, "Zada Do");

        addToAmnt[msg.sender] += msg.value;

    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getEthPrice(uint256 eth) public view returns (uint256) {
        uint256 tPrice = (eth * getPrice())/1000000000000000000;
        return tPrice;
    }



    function withdraw() public payable {
        // address sAdd = msg.sender;

        require(addToAmnt[msg.sender] >= msg.value, "amount zada bta rhe ho");

        payable(msg.sender).transfer(msg.value);

        addToAmnt[msg.sender] -= msg.value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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