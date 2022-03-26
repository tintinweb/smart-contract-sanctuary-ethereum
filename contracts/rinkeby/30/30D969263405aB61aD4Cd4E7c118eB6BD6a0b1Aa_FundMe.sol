//SPDX-License-Identifier : MIT
pragma solidity ^0.8.0;
import "AggregatorV3Interface.sol";

contract FundMe {
///	using SafeMathChainlink for uint256;

	uint256 answer;

	mapping(address => uint256) public addressToAmountFunded;

	function fund() public payable{
		addressToAmountFunded[msg.sender] += msg.value;
		
	}

	function getVersion()public view returns(uint256) {
		AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
		return priceFeed.version();	
	}


	function getPrice() public view returns(uint256) {
		AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
		return uint256 (answer *10000000000);
	}

	function getConversionRate(uint256 ethAmount) public view returns(uint256) {
		uint256 usdPrice = getPrice();
		uint256 amountInUsd = (usdPrice * ethAmount)/ 1000000000000000000;
		return amountInUsd;
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