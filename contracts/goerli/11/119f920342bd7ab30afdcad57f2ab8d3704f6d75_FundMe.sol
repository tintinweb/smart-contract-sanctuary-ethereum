// SPDX-License-Identifier: MIT
// Pragma
pragma solidity ^0.8.8;

// Imports
import "./PriceConverter.sol";

// Error Codes
error FundMe__NotOwner();

// Interfaces, Libraries, Contracts

/** @title A contract for crowd funding
 *  @author Patrick Collins
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feeds as our library
 */
contract FundMe {
  // Type Declarations
  using PriceConverter for uint256;

  // State Variables
  mapping(address => uint256) private s_addressToAmountFunded;
  address[] private s_funders;
  address private immutable i_owner;
  uint256 public constant MINIMUM_USD = 50 * 1e18;
  AggregatorV3Interface private s_priceFeed;

  // Modifiers
  modifier onlyOwner() {
    // require(msg.sender == i_owner, "Sender is not owner!");
    // custom
    if (msg.sender != i_owner) {
      revert FundMe__NotOwner();
    }
    _; // execute rest of code in the function if require condition is met
  }

  // Functions
  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  // add receive() & fallback() functions in case someone sends ETH directly to the contract without calling the fund function
  /*
  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }
  */

  /** @notice This function funds this contract */
  function fund() public payable {
    /*
    require(
      msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
      "You need to spend more ETH!"
    ); // 1e18 wei == 1 eth
    */
    // use revert instead of require to save gas
    if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
      revert("You need to spend more ETH!");
    }
    s_funders.push(msg.sender);
    s_addressToAmountFunded[msg.sender] += msg.value;
  }

  function withdraw() public payable onlyOwner {
    for (
      uint256 funderIndex = 0;
      funderIndex < s_funders.length;
      funderIndex++
    ) {
      address funder = s_funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }
    // reset the array
    s_funders = new address[](0);

    // actually withdraw the funds

    // Note:
    // i_owner = msg.sender and is of type address
    // payable(i_owner) is of type payable address
    // this is called typecasting
    // only payable addresses can send funds

    (
      bool callSuccess, /* bytes memory dataReturned */

    ) = payable(i_owner).call{value: address(this).balance}("");
    // require(callSuccess, "Transfer failed");
    // use revert instead of require to save gas
    if (!callSuccess) {
      revert("Transfer failed");
    }
  }

  function cheaperWithdraw() public payable onlyOwner {
    address[] memory funders = s_funders;
    // mapping can't be in memory, sorry!
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }
    // reset the array
    s_funders = new address[](0);
    (bool callSuccess, ) = payable(i_owner).call{value: address(this).balance}(
      ""
    );
    require(callSuccess, "Transfer failed");
  }

  // getters
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

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    // ETH in terms of USD
    // e.g. 3000.00000000 (8 decimal places)
    // msg.value has 18 decimal places (1 ETH == 1000000000000000000 Wei)
    return uint256(price * 1e10); // to match up the units
  }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
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