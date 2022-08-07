// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();

/**
 * @title A contract for crowd funding
 * @author Me
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
  using PriceConverter for uint256;

  uint256 public constant MINIMUM_USD = 50 * 1e18;
  address private immutable owner;
  address[] private funders;
  AggregatorV3Interface private priceFeed;
  mapping(address => uint256) private addressToAmountFunded;

  event Funded(address sender, uint256 amount);

  modifier onlyOwner() {
    if (msg.sender != owner) revert FundMe__NotOwner();
    _;
  }

  constructor(address priceFeedAddress) {
    owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }

  /**
   * @notice This function funds this contract
   * @dev This implements price feeds as our library
   */
  function fund() public payable {
    require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough");
    addressToAmountFunded[msg.sender] += msg.value;
    funders.push(msg.sender);
    emit Funded(msg.sender, msg.value);
  }

  /**
   * @notice This function withdraws funds from this contract to its owner
   */
  function withdraw() public payable onlyOwner {
    address[] memory funders_ = funders;
    for (uint256 funderIndex = 0; funderIndex < funders_.length; funderIndex++) {
      address funder = funders_[funderIndex];
      addressToAmountFunded[funder] = 0;
    }

    funders = new address[](0);
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success, "Transfer failed");
  }

  function getOwner() external view returns (address) {
    return owner;
  }

  function getFunder(uint256 index) external view returns (address) {
    return funders[index];
  }

  function getAddressToAmountFunded(address funder) external view returns (uint256) {
    return addressToAmountFunded[funder];
  }

  function getPriceFeed() external view returns (AggregatorV3Interface) {
    return priceFeed;
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
pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    // ETH/USD rate in 18 digit
    return uint256(price * 1e10);
  }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    return (ethAmount * getPrice(priceFeed)) / 1e18;
  }
}