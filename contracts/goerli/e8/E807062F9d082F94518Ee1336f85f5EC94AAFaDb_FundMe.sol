// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import './PriceConverter.sol';

error FundMe__NotOwner();

/**
 * @title A contract for crowd funding
 * @author Fendross
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
	using PriceConverter for uint256;

	uint256 public constant MINIMUM_USD = 50 * 1e18;
	address[] public s_funders;
	mapping(address => uint256) public s_addressToAmountFunded;
	address private immutable i_owner;

	AggregatorV3Interface public s_priceFeed;

	modifier onlyOwner() {
		if (msg.sender != i_owner) revert FundMe__NotOwner();
		_;
	}

	constructor(address s_priceFeedAddress) {
		i_owner = msg.sender;
		s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
	}

	// what if someone sends eth here without calling fund()?
	// receive and fallback
	receive() external payable {
		fund();
	}

	fallback() external payable {
		fund();
	}

	/**
	 * @notice This function funds this contract
	 * @dev Implements price feeds
	 */
	function fund() public payable {
		// msg.value is considered the first parameter of the library functions
		require(
			msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
			"Didn't send enough!"
		); // 1e18 = 10 ** 18, ETH has 18 decimals
		s_funders.push(msg.sender);
		s_addressToAmountFunded[msg.sender] += msg.value;
	}

	/**
	 * @dev allows only the owner to withdraw the contract's balance
	 */
	function withdraw() public onlyOwner {
		// require(msg.sender == owner, 'Sender is not owner!');

		for (
			uint256 funderIndex = 0;
			funderIndex < s_funders.length;
			funderIndex++
		) {
			address funder = s_funders[funderIndex];
			s_addressToAmountFunded[funder] = 0;
		}

		// reset an array: new type[](amoutOfObjectsToStart)
		s_funders = new address[](0);

		// payable(msg.sender).transfer(address(this).balance);

		// bool sendSuccess = payable(msg.sender).send(address(this).balance);
		// require(sendSuccess, 'Send failed');

		// call, recommended
		(
			bool callSuccess, /* bytes memory dataReturned */

		) = payable(msg.sender).call{value: address(this).balance}('');
		require(callSuccess, 'Failed');
	}

	/**
	 * @dev this function implements a first gas optimization saving the s_funders to memory and reading from that instead
	 */
	function cheaperWithdraw() public payable onlyOwner {
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

	// Getter functions (view / pure)
	function getOwner() public view returns (address) {
		return i_owner;
	}

	function getFunder(uint256 index) public view returns (address) {
		return s_funders[index];
	}

	function getAddressToAmountFunded(address funder)
		public
		view
		returns (uint256)
	{
		return s_addressToAmountFunded[funder];
	}

	function getPriceFeed() public view returns (AggregatorV3Interface) {
		return s_priceFeed;
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