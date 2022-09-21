// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity 0.8.17;
// 2. Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./libs/PriceConverter.sol";

// 3. Interfaces, Libraries, Contracts
error FundMe__NotOwner();

/**@title A sample Funding Contract
 * @author Patrick Collins
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
	// Type Declarations
	using PriceConverter for uint256;

	// State variables
	uint256 public constant MINIMUM_USD = 50 * 10**18;
	address private immutable iOwner;
	uint8 private immutable iTag;
	address[] private sFunders;
	mapping(address => uint256) private sAddressToAmountFunded;
	AggregatorV3Interface private sPriceFeed;

	// Events (we have none!)

	// Modifiers
	modifier onlyOwner() {
		// require(msg.sender == iOwner);
		if (msg.sender != iOwner) revert FundMe__NotOwner();
		_;
	}

	// Functions Order:
	//// constructor
	//// receive
	//// fallback
	//// external
	//// public
	//// internal
	//// private
	//// view / pure

	constructor(address priceFeed, uint8 tag) {
		sPriceFeed = AggregatorV3Interface(priceFeed);
		iOwner = msg.sender;
		iTag = tag;
	}

	function getBalance() external view returns (uint256) {
		return address(this).balance;
	}

	/// @notice Funds our contract based on the ETH/USD price
	function fund() public payable {
		require(msg.value.getConversionRate(sPriceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
		// require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
		sAddressToAmountFunded[msg.sender] += msg.value;
		sFunders.push(msg.sender);
	}

	function withdraw() public onlyOwner {
		for (uint256 funderIndex = 0; funderIndex < sFunders.length; funderIndex++) {
			address funder = sFunders[funderIndex];
			sAddressToAmountFunded[funder] = 0;
		}
		sFunders = new address[](0);
		// Transfer vs call vs Send
		// payable(msg.sender).transfer(address(this).balance);

		// solhint-disable-next-line
		(bool success, ) = iOwner.call{value: address(this).balance}("");
		require(success, "Failed to send back to owner");
	}

	function cheaperWithdraw() public onlyOwner {
		address[] memory funders = sFunders;
		// mappings can't be in memory, sorry!
		for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
			address funder = funders[funderIndex];
			sAddressToAmountFunded[funder] = 0;
		}
		sFunders = new address[](0);
		// solhint-disable-next-line
		(bool success, ) = iOwner.call{value: address(this).balance}("");
		require(success, "Failed to send back to owner");
	}

	/** @notice Gets the amount that an address has funded
	 *  @param fundingAddress the address of the funder
	 *  @return the amount funded
	 */
	function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
		return sAddressToAmountFunded[fundingAddress];
	}

	function getVersion() public view returns (uint256) {
		return sPriceFeed.version();
	}

	function getFunder(uint256 index) public view returns (address) {
		return sFunders[index];
	}

	function getOwner() public view returns (address) {
		return iOwner;
	}

	function getPriceFeed() public view returns (AggregatorV3Interface) {
		return sPriceFeed;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
	function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
		(, int256 answer, , , ) = priceFeed.latestRoundData();
		// ETH/USD rate in 18 digit
		return uint256(answer * 10000000000);
	}

	// 1000000000
	// call it get fiatConversionRate, since it assumes something about decimals
	// It wouldn't work for every aggregator
	function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
		internal
		view
		returns (uint256)
	{
		uint256 ethPrice = getPrice(priceFeed);
		uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
		// the actual ETH/USD conversation rate, after adjusting the extra 0s.
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