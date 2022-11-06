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
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

/**
 *  @title A contract for crowd funding
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feeds as our library
 */
contract FundMe {
	using PriceConverter for uint256;

	// Public State Variables
	uint256 public constant MINIMUM_USD = 5 * 10**18;

	// Private State Variables
	AggregatorV3Interface private s_priceFeed;
	address[] private s_funders;
	address private immutable i_owner;
	mapping(address => uint256) private s_addressToAmountFunded;

	modifier onlyOwner() {
		// require(msg.sender == owner);
		if (msg.sender != i_owner) revert FundMe__NotOwner();
		_;
	}

	constructor(address priceFeedAddress) {
		i_owner = msg.sender;
		s_priceFeed = AggregatorV3Interface(priceFeedAddress);
	}

	fallback() external payable {
		fund();
	}

	receive() external payable {
		fund();
	}

	/**
	 *  @notice This function funds this contract
	 */
	function fund() public payable {
		require(
			msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
			"You need to spend more ETH!"
		);
		s_addressToAmountFunded[msg.sender] += msg.value;
		s_funders.push(msg.sender);
	}

	/**
	 *  @notice This function withdraw funds
	 */
	function withdraw() public onlyOwner {
		for (
			uint256 funderIndex = 0;
			funderIndex < s_funders.length;
			funderIndex++
		) {
			address funder = s_funders[funderIndex];
			s_addressToAmountFunded[funder] = 0;
		}

		s_funders = new address[](0);

		// method 1: transfer
		// payable(msg.sender).transfer(address(this).balance);

		// method 2: send
		// bool sendSuccess = payable(msg.sender).send(address(this).balance);
		// require(sendSuccess, "Send failed");

		// method 3 (preferred): call
		(bool callSuccess, ) = payable(msg.sender).call{
			value: address(this).balance
		}("");
		require(callSuccess, "Call failed");
	}

	/**
	 *  @notice This function withdraw funds (cheaper) as it loads funders into the memory
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
		(bool callSuccess, ) = payable(msg.sender).call{
			value: address(this).balance
		}("");
		require(callSuccess, "Call failed");
	}

	/**
	 *  @notice This function is a getter of the owner address
	 */
	function getOwner() public view returns (address) {
		return i_owner;
	}

	/**
	 *  @notice This function is a getter of the funder address
	 *  @param index The index of the funder
	 *  @return address The address of the funder
	 */
	function getFunder(uint256 index) public view returns (address) {
		return s_funders[index];
	}

	/**
	 *  @notice This function returns the amount funded by an address
	 *  @param funder The address of the funder
	 *  @return uint256 The amount funded by the funder
	 */
	function getAddressToAmountFunded(address funder)
		public
		view
		returns (uint256)
	{
		return s_addressToAmountFunded[funder];
	}

	/**
	 *  @notice This function returns the price feed used in the contract
	 *  @return AggregatorV3Interface The price feed used in the contract
	 */
	function getPriceFeed() public view returns (AggregatorV3Interface) {
		return s_priceFeed;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
	// We could make this public, but then we'd have to deploy it
	function getPrice(AggregatorV3Interface priceFeed)
		internal
		view
		returns (uint256)
	{
		// Goerli ETH / USD Address
		// https://docs.chain.link/docs/ethereum-addresses/
		// AggregatorV3Interface priceFeed = AggregatorV3Interface(
		//     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
		// );

		(, int256 answer, , , ) = priceFeed.latestRoundData();
		// ETH/USD rate in 18 digit
		return uint256(answer * 10000000000);
		// or (Both will do the same thing)
		// return uint256(answer * 1e10); // 1* 10 ** 10 == 10000000000
	}

	// 1000000000
	function getConversionRate(
		uint256 ethAmount,
		AggregatorV3Interface priceFeed
	) internal view returns (uint256) {
		uint256 ethPrice = getPrice(priceFeed);
		uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
		// or (Both will do the same thing)
		// uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // 1 * 10 ** 18 == 1000000000000000000
		// the actual ETH/USD conversion rate, after adjusting the extra 0s.
		return ethAmountInUsd;
	}
}