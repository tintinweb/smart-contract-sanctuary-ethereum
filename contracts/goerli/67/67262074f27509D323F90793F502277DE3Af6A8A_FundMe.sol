// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "AggregatorV3Interface.sol";

// Your contract code here






contract FundMe {

    mapping(address => uint256) public addtofunded;

    function fund() public payable {
        addtofunded[msg.sender] += msg.value;
    }
    function get_version() public view returns (uint256){
        AggregatorV3Interface priceFeed = 
          AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function get_price() public view returns(uint256){
        AggregatorV3Interface priceFeed = 
      AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000);
    }

    function convert(uint256 ethamt) public view returns(uint256){

        uint256 ethprice = get_price();

        uint256 ethamttousd = (ethprice * ethamt) / 1000000000000000000; 
        return ethamttousd;

    } 

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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