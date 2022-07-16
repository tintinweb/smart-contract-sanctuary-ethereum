//SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();
error NotEhough();
error WithdrawFailed();

contract FundMe {
	using PriceConverter for uint256;

	uint256 public constant MIN_USD = 50 * 1e18;

	address[] public funders;
	mapping(address => uint256) public addressToAmountFunded;

	address public immutable i_owner;

	AggregatorV3Interface public priceFeed;

	constructor(address priceFeedAddress) {
		i_owner = msg.sender;
		priceFeed = AggregatorV3Interface(priceFeedAddress);
	}

	function fund() public payable {
		if (msg.value.getConvertionRate(priceFeed) < MIN_USD) {
			revert NotEhough();
		}
		funders.push(msg.sender);
		addressToAmountFunded[msg.sender] += msg.value; //@audit
	}

	function withdraw() public ownerAcces {
		for (
			uint256 funderIndex = 0;
			funderIndex < funders.length;
			funderIndex++
		) {
			address funder = funders[funderIndex];
			addressToAmountFunded[funder] = 0;
		}

		funders = new address[](0);

		(bool callSuccess, ) = payable(msg.sender).call{
			value: address(this).balance
		}("");
		if (!callSuccess) {
			revert WithdrawFailed();
		}
	}

	modifier ownerAcces() {
		if (msg.sender != i_owner) {
			revert NotOwner();
		}
		_;
	}

	receive() external payable {
		fund();
	}

	fallback() external payable {
		fund();
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
pragma solidity 0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
	function getPrice(AggregatorV3Interface priceFeed)
		internal
		view
		returns (uint256)
	{
		(, int256 answer, , , ) = priceFeed.latestRoundData();
		return uint256(answer * 1e10);
	}

	function getConvertionRate(
		uint256 ethAmount,
		AggregatorV3Interface priceFeed
	) internal view returns (uint256) {
		uint256 ethPrice = getPrice(priceFeed);
		uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
		return ethAmountInUsd;
	}
}