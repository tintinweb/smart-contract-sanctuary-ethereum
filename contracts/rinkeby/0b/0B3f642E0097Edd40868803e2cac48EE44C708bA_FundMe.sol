// SPDX-License-Identifier: UNLICENSED
// Pragma
pragma solidity  ^0.8.9;

// Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// Error Codes
error FundMe__NotOwner();

// Interfaces, Libraries, Contracts

/** @title A contract for crowd funding
 *  @author Antonio Manuel Pérez López
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feeds as our library
 * 
*/
contract FundMe {
  // Type Declarations
  using PriceConverter for uint256;

  // State Variables
  mapping(address => uint256) private s_addressToAmountFunded;
  address[] private s_funders;
  address private immutable i_owner;
  uint256 public constant MINIMUN_USD = 50 * 1e18;
  AggregatorV3Interface private s_priceFeed;

  modifier onlyOwner {
    if(msg.sender != i_owner) revert FundMe__NotOwner();
    _;
  }

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }

  /**
   *  @notice This function fund this contract
   */
  function fund() public payable {
    require(msg.value.getConversionRate(s_priceFeed) >= MINIMUN_USD, "Not enough");
    s_funders.push(msg.sender);
    s_addressToAmountFunded[msg.sender] = msg.value;
  }

  function withdraw() public onlyOwner {
    for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
      address funder = s_funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0);
    (bool callSuccess,) = payable(msg.sender)
      .call{value: address(this).balance}("");
    require(callSuccess, "Call failed");
  }

  function cheaperWithdraw() public payable onlyOwner {
    address[] memory funders = s_funders;
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0);
    (bool success,) = i_owner.call{value: address(this).balance}("");
    require(success, "Call failed");
  }

  // View / Pure
  function getOwner() public view returns(address) {
    return i_owner;
  }
  function getFunders() public view returns(address[]  memory) {
    return s_funders;
  }
  function getFunder(uint256 _index) public view returns(address) {
    return s_funders[_index];
  }
  function getAddressToAmountFunded(address _funder) public view returns(uint256) {
    return s_addressToAmountFunded[_funder];
  }

  function getPriceFeed() public view returns(AggregatorV3Interface) {
    return s_priceFeed;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity  ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
    // address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    (, int256 price,,,) = priceFeed.latestRoundData();
    return uint256(price * 1e10);
  }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountUsd = (ethPrice * ethAmount) / 1e18;
    return ethAmountUsd;
  }

  // function getVersion(AggregatorV3Interface priceFeed) internal view returns(uint256) {
  //   return priceFeed.version();
  // }
}