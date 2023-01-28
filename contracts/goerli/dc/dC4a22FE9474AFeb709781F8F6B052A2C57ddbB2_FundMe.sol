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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
	using PriceConverter for uint256;

	AggregatorV3Interface public priceFeed;

	constructor(address priceFeedAddress) {
		// immutable variable only can be declared one time.
		i_owner = msg.sender;
		priceFeed = AggregatorV3Interface(priceFeedAddress);
	}

	uint256 public constant MINIMUM_USD = 10 * 1e18;
	address public immutable i_owner;
	mapping(address => uint256) public addressToAmountFunded;
	address[] public funders;

	function fund() public payable {
		require(
			msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
			"Didn't send enough!"
		);
		funders.push(msg.sender);
		addressToAmountFunded[msg.sender] += msg.value;
	}

	function withdraw() public onlyOwner {
		for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
			address funder = funders[funderIndex];
			addressToAmountFunded[funder] = 0;
		}
		funders = new address[](0);
		// // transfer throw error if failed
		// payable(msg.sender).transfer(address(this).balance);
		// // send return bool and need to require to revert
		// bool sendSuccess = payable(msg.sender).send(address(this).balance);
		// require(sendSuccess, "Send failed");
		// call recommended and need to require to revert
		(bool callSuccess, ) = payable(msg.sender).call{
			value: address(this).balance
		}("");
		require(callSuccess, "Call failed");
	}

	modifier onlyOwner() {
		// require(msg.sender == i_owner);
		if (msg.sender != i_owner) {
			revert NotOwner();
		}
		_;
	}

	receive() external payable {
		fund();
	}

	// call CALLDATA with 0x00
	fallback() external payable {
		fund();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
	function getPrice(
		AggregatorV3Interface priceFeed
	) internal view returns (uint256) {
		// ABI
		// Address Goerli testnet ETH/USD 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
		(, int price, , , ) = priceFeed.latestRoundData();
		// exact same decimal precision with caller
		return uint256(price * 1e10);
	}

	function getConversionRate(
		uint256 ethAmount,
		AggregatorV3Interface priceFeed
	) internal view returns (uint256) {
		uint256 ethPrice = getPrice(priceFeed);
		// both have 18 precision
		uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
		return ethAmountInUsd;
	}
}