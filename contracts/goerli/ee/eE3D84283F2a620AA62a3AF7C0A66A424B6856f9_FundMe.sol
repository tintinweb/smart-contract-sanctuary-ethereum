// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import './PriceConverter.sol';

error NotOwner();

contract FundMe {
	using PriceConverter for uint256;

	uint256 public constant MINIMUM_USD = 50 * 1e18;
	address[] public funders;
	mapping(address => uint256) public addressToAmountFunded;
	address public immutable i_owner;

	AggregatorV3Interface public priceFeed;

	constructor(address priceFeedAddress) {
		i_owner = msg.sender;
		priceFeed = AggregatorV3Interface(priceFeedAddress);
	}

	function fund() public payable {
		// msg.value is considered the first parameter of the library functions
		(
			msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
			"Didn't send enough!"
		); // 1e18 = 10 ** 18, ETH has 18 decimals
		funders.push(msg.sender);
		addressToAmountFunded[msg.sender] += msg.value;
	}

	function withdraw() public onlyOwner {
		// require(msg.sender == owner, 'Sender is not owner!');

		for (
			uint256 funderIndex = 0;
			funderIndex < funders.length;
			funderIndex++
		) {
			address funder = funders[funderIndex];
			addressToAmountFunded[funder] = 0;
		}

		// reset an array: new type[](amoutOfObjectsToStart)
		funders = new address[](0);

		// withdraw funds

		// transfer, capped at 2300 gas, if failed throws error
		// payable(msg.sender).transfer(address(this).balance);

		// send, capped at 2300, returns a bool
		// bool sendSuccess = payable(msg.sender).send(address(this).balance);
		// require(sendSuccess, 'Send failed');

		// call, recommended
		(
			bool callSuccess, /* bytes memory dataReturned */

		) = payable(msg.sender).call{value: address(this).balance}('');
		require(callSuccess, 'Failed');
	}

	modifier onlyOwner() {
		if (msg.sender != i_owner) {
			revert NotOwner();
		}
		_; // do the rest of the code
	}

	// what if someone sends eth here without calling fund()?

	// receive and fallback
	receive() external payable {
		fund();
	}

	fallback() external payable {
		fund();
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

// Can't have state variables and can't send ether, all func will be internal
library PriceConverter {
	function getPrice(AggregatorV3Interface priceFeed)
		internal
		view
		returns (uint256)
	{
		// We're interacting with a contract outside the project --> address (0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e)
		// and ABI
		(, int256 price, , , ) = priceFeed.latestRoundData();

		return uint256(price * 1e10); // price of ETH in terms of USD
	}

	function getConversionRate(
		uint256 ethAmount,
		AggregatorV3Interface priceFeed
	) internal view returns (uint256) {
		uint256 ethPrice = getPrice(priceFeed);
		uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // because they'd have 36 digits
		return ethAmountInUsd;
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