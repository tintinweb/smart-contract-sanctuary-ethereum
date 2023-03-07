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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import './PriceConverter.sol';

error FundMe_NotOwner();
error FundMe_NotAboveMinimum();
error FundMe_CallFailed();
error FundMe_NotEnoughEth();

/// @title A contract for crowd funding
/// @author Teodor Dimitrov
/// @notice This contract is to demo a sample funding contract
/// @dev This implements price feeds as our library

contract FundMe {
	using PriceConverter for uint256;
	uint256 public constant MINIMUM_USD = 100 * 10 ** 18;
	address[] private s_funders;
	mapping(address => uint256) private s_addressToAmountFunded;
	address private immutable i_owner;
	AggregatorV3Interface private s_priceFeed;

	modifier onlyOwner() {
		if (msg.sender != i_owner) {
			revert FundMe_NotOwner();
		}
		_;
	}

	constructor(address priceFeedAddress) {
		s_priceFeed = AggregatorV3Interface(priceFeedAddress);
		i_owner = msg.sender;
	}

	receive() external payable {
		fund();
	}

	fallback() external payable {
		fund();
	}

	/// @notice This function funds this contract

	function fund() public payable {
		if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
			revert FundMe_NotEnoughEth();
		}
		s_funders.push(msg.sender);
		s_addressToAmountFunded[msg.sender] = msg.value;
	}

	function withdraw() public payable onlyOwner {
		address[] memory funders = s_funders;
		for (
			uint256 funderIndex = 0;
			funderIndex < funders.length;
			funderIndex++
		) {
			address funder = funders[funderIndex];
			s_addressToAmountFunded[funder] = 0;
		}
		s_funders = new address[](0);
		(bool success, ) = i_owner.call{value: address(this).balance}('');
		require(success);
	}

	function getOwner() public view returns (address) {
		return i_owner;
	}

	function getFunder(uint256 index) public view returns (address) {
		return s_funders[index];
	}

	function getAddressToAmountFunded(
		address funder
	) public view returns (uint256) {
		return s_addressToAmountFunded[funder];
	}

	function getPriceFeed() public view returns (AggregatorV3Interface) {
		return s_priceFeed;
	}
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

library PriceConverter {
	function getPrice(
		AggregatorV3Interface priceFeedAddress
	) internal view returns (uint256) {
		AggregatorV3Interface priceFeed = AggregatorV3Interface(
			priceFeedAddress
		);
		(, int256 price, , , ) = priceFeed.latestRoundData();
		return uint256(price * 1e10);
	}

	function getConversionRate(
		uint256 ethAmount,
		AggregatorV3Interface priceFeedAddress
	) internal view returns (uint256) {
		uint256 ethPrice = getPrice(priceFeedAddress);
		uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
		return ethAmountInUsd;
	}
}