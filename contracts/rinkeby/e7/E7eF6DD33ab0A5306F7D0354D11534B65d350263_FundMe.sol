// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Imports
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import './PriceConverter.sol';

// Error Codes
error FundMe__NotOwner();

// Interfaces, Libraries, Contracts

// More about Solidity comments can be found here:
// https://docs.soliditylang.org/en/develop/natspec-format.html

/// @title A contract for crowd funding
/// @author Matúš Jurko
/// @notice This contract is to demo a sample funding contract
/// @dev This implements price feeds as our library
contract FundMe {
  // Type Declarations
  using PriceConverter for uint256;

  // State Variables
  uint256 public constant MINIMUM_USD = 50 * 10**18;

  mapping(address => uint256) private s_addressToAmountFunded;
  AggregatorV3Interface private s_priceFeed;
  address private immutable i_owner;
  address[] private s_funders;

  // Modifiers
  modifier onlyOwner() {
    if (msg.sender != i_owner) revert FundMe__NotOwner();
    _;
  }

  // Function Order:
  // 1. constructor
  // 2. receive
  // 3. fallback
  // 4. external
  // 5. public
  // 6. internal
  // 7. private
  // 8. view / pure

  constructor(address priceFeedAddress) {
    i_owner = msg.sender; // Owner of the contract
    s_priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  // receive() external payable {
  //   fund();
  // }

  // fallback() external payable {
  //   fund();
  // }

  /// @notice This function funds this contract
  /// @dev This implements price feeds as our library
  function fund() public payable {
    require(
      msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
      'You need to spend more ETH!'
    );

    s_addressToAmountFunded[msg.sender] += msg.value;
    s_funders.push(msg.sender);
  }

  /// @notice This function withdraws funds from this contract
  function withdraw() public payable onlyOwner {
    for (
      uint256 funderIndex = 0;
      funderIndex < s_funders.length;
      funderIndex++
    ) {
      address funder = s_funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }

    s_funders = new address[](0);
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }('');

    require(callSuccess, 'Call failed!');
  }

  /// @notice This function withdraws funds from this contract
  function cheaperWithdraw() public payable onlyOwner {
    // NOTE: Mappings can't be in memory!
    address[] memory funders = s_funders;

    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }

    s_funders = new address[](0);
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }('');

    require(callSuccess, 'Call failed!');
  }

  /// @notice This function returns the version of price feed
  /// @return The version of price feed
  function getVersion() public view returns (uint256) {
    return s_priceFeed.version();
  }

  /// @notice This function returns the owner of this contract
  function getOwner() public view returns (address) {
    return i_owner;
  }

  /// @notice This function returns the address of a specific funder
  function getFunder(uint256 index) public view returns (address) {
    return s_funders[index];
  }

  /// @notice This function returns the amount of ETH funded by a specific funder
  function getAddressToAmountFunded(address funder)
    public
    view
    returns (uint256)
  {
    return s_addressToAmountFunded[funder];
  }

  /// @notice This function returns the price feed
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
pragma solidity ^0.8.8;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    return uint256(answer * 10000000000); // ETH/USD rate in 18 digit
  }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    // the actual ETH/USD conversion rate, after adjusting the extra 0s.
    return ethAmountInUsd;
  }
}