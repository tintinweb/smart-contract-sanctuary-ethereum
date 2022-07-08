// SPDX-License-Identifier: MIT
// > Pragma
pragma solidity ^0.8.7;
// > Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";
// > Error Codes
error FundMe__NotOwner();

// > Interfaces, Libraries, Contracts
/** @title A contract for crowd funding
 * @author jsmjsm
 * @notice This contract is to demo a sample
 * @dev This implement price feed as our libraay
 */
contract FundMe {
	// * Type Decalarations
	using PriceConverter for uint256;

	// * State Variavles
	uint256 public constant MINIMUN_USD = 1 * 1e18;
	address[] private s_funders;
	mapping(address => uint256) public s_addressToAmountFunded;
	address private immutable i_owner;
	AggregatorV3Interface public s_priceFeed;

	// * Modifier
	modifier onlyOwner() {
		// require(msg.sender == i_owner, "Sender is not owner!");
		if (msg.sender != i_owner) {
			revert FundMe__NotOwner();
		}
		_;
	}

	// * Functions
	constructor(address priceFeedAddress) {
		i_owner = msg.sender;
		s_priceFeed = AggregatorV3Interface(priceFeedAddress);
	}

	// ** Reveive & Fallback
	receive() external payable {
		fund();
	}

	fallback() external payable {
		fund();
	}

	// ** Public
	/**
	 * @notice This functino funds this contract
	 * @dev This implement price feed as our libraay
	 */
	function fund() public payable {
		require(
			msg.value.getConversionRate(s_priceFeed) >= MINIMUN_USD,
			"You need to spend more ETH!"
		); // 1e18 = 1 * 10 ** 18
		// 18 decimals
		s_funders.push(msg.sender);
		s_addressToAmountFunded[msg.sender] += msg.value;
	}

	function withdraw() public onlyOwner {
		for (
			uint256 funderIndex = 0;
			funderIndex < s_funders.length;
			funderIndex++
		) {
			// code
			address funder = s_funders[funderIndex];
			s_addressToAmountFunded[funder] = 0;
		}
		// reset array
		s_funders = new address[](0);
		// withdraw by
		(bool callSucess, ) = payable(msg.sender).call{
			value: address(this).balance
		}("");
		require(callSucess, "Call send failed!");
	}

	function cheaperWithdraw() public onlyOwner {
		address[] memory funders = s_funders;
		// mapping cant be in memory
		for (
			uint256 funderIndex = 0;
			funderIndex < funders.length;
			funderIndex++
		) {
			// code
			address funder = funders[funderIndex];
			s_addressToAmountFunded[funder] = 0;
		}
		s_funders = new address[](0);
		(bool success, ) = i_owner.call{value: address(this).balance}("");
		require(success, "Call send failed!");
	}

	// view/pure
	function getOwner() public view returns (address) {
		return i_owner;
	}

	function getFunder(uint256 index) public view returns (address) {
		require(index < s_funders.length, "Index out of range!");
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
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
	function getPrice(AggregatorV3Interface priceFeed)
		internal
		view
		returns (uint256)
	{
		// ABI
		// Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
		// AggregatorV3Interface priceFeed = AggregatorV3Interface(
		// 	0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
		// );
		(, int256 price, , , ) = priceFeed.latestRoundData();
		// ETH in terms of USD
		// 3000.00000000

		// ETH/USD rate in 18 digit
		return uint256(price * 1e10); // 1**10 = 10000000000
	}

	function getConversionRate(
		uint256 ethAmount,
		AggregatorV3Interface priceFeed
	) internal view returns (uint256) {
		uint256 ethPrice = getPrice(priceFeed);
		uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
		return ethAmountInUsd;
	}
}