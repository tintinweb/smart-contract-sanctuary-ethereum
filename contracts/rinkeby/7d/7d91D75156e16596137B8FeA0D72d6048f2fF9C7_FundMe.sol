// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import './PriceConverter.sol';

// custom error saving gas
error NotOwner();

// Creating costs about 859,757 gas
contract FundMe {
	using PriceConverter for uint256;

	// Using constant saves gas - maybe about 2000 gas
	uint256 public constant MIN_USD = 50 * 1e18;

	address[] public funders;
	mapping(address => uint256) public addressToAmountFunded;

	// Using immutable saves gas - maybe about 2000 gas
	// immutable is where the value changes but is only called once.
	address public immutable i_owner;

	AggregatorV3Interface public priceFeed;

	constructor(address priceFeedAddress) {
		// ran as soon as contract in initilized
		i_owner = msg.sender;
		priceFeed = AggregatorV3Interface(priceFeedAddress);
	}

	function fund() public payable {
		// We want to set a minimum fund amout in USD.
		// Anything below require() needs to match the first param to continue
		// otherwise anything above is undone.
		// Able to use getConversionRate() on msg.value as we are importing the library PriceConverter
		// where the function exists.
		require(
			msg.value.getConversionRate(priceFeed) >= MIN_USD,
			"Didn't send enough ETH."
		); // 1e18 == 1 * 10^18 == 1000000000000000000
		// msg.value will have 18 decimal places.
		funders.push(msg.sender);
		addressToAmountFunded[msg.sender] += msg.value;
	}

	// only owner can call this function
	// onlyOwner is a modifier which runs before running the functions code.
	function withdraw() public onlyOwner {
		// require(msg.sender == owner, "Sender is no Owner!");

		for (uint256 i = 0; i < funders.length; i++) {
			address funder = funders[i];

			addressToAmountFunded[funder] = 0;
		}
		// reset array
		// remove all funders as they are no longer funders if they have funded 0 amount
		funders = new address[](0);
		// actually withdraw funds

		// // == transfer ==
		// // If this fails it will throw error and revert transaction
		// // msg.sender == address
		// // payable(msg.sender) == payable address
		// payable(msg.sender).transfer(address(this).balance);

		// // == send ==
		// // If this fails then it will return a boolean of false and not revert
		// bool sendSuccess = payable(msg.sender).send(address(this).balance);
		// // It will only revert seen as this condition to this require is false.
		// require(sendSuccess, "Send Failed");

		// == call ==
		// dont want to call function so leave it blank e.g. ""
		// dont call a function but pass in address
		// returns 2 variables
		// bytes are arrays so needs to be put in memory. Similar with strings
		// Warning for bytes memory dataReturned
		(bool callSuccess, ) = payable(msg.sender).call{
			value: address(this).balance
		}('');
		require(callSuccess, 'Call Failed');

		// Visit: solidity-by-example.org/sending-ether for more information.
	}

	modifier onlyOwner() {
		// require(msg.sender == i_owner, "Sender is not owner!");
		if (msg.sender != i_owner) {
			revert NotOwner();
		}
		// represents reset of code from the function it was used on.
		// if this was above require the function code would run first then the require instead.
		_;
	}

	// What happens if someone sends this contract ETH without calling fund()
	// This is make them forced to call fund() even if they dont directly call it
	// or another function
	// == receive ==
	receive() external payable {
		fund();
	}

	// == fallback ==
	fallback() external payable {
		fund();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

library PriceConverter {
	// instead of using ChainLink for the priceFeed address we pass it in from FundMe
	// constructor which gets it from when it is deployed
	function getPrice(AggregatorV3Interface priceFeed)
		internal
		view
		returns (uint256)
	{
		// Need:
		// - ABI
		// - Address for ETH -> USD - 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
		// AggregatorV3Interface priceFeed = AggregatorV3Interface(
		// 	0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
		// );
		(, int256 price, , , ) = priceFeed.latestRoundData();
		// ETH in terms of USD
		return uint256(price * 1e10);
	}

	// function getVersion() internal view returns (uint256) {
	// 	AggregatorV3Interface priceFeed = AggregatorV3Interface(
	// 		0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
	// 	);
	// 	return priceFeed.version();
	// }

	// Param is automatically passed in on the thing it has been called on.
	// e.g. msg.value.getConversionRate()
	// msg.value will be passed in the param automatically.
	// But if there was a second param we would need to pass that in the brackets.
	function getConversionRate(
		uint256 ethAmount,
		AggregatorV3Interface priceFeed
	) internal view returns (uint256) {
		uint256 ethPrice = getPrice(priceFeed);
		// 1500_000000000000000000 == 1 ETH in USD
		// 1_000000000000000000 == 1 ETH
		uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // need to devide so it doesnt have extra 0s on the end.
		// 1500 == ETH in USD without the extra 18 zeros
		return ethAmountInUsd;
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