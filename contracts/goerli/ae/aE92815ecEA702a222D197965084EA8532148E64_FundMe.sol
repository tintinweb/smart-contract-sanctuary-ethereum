//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PriceConverter.sol";

error FundMe__notOwner();

/** @title A contract for crowd funding
 *  @author Me
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feeds as our library
 */

contract FundMe {
  // Type Declarations
  using PriceConverter for uint256;

  // State Variables
  uint256 public constant MINIMUM_USD = 50 * 1e18;
  address[] private s_funders;
  mapping(address => uint256) private s_addressToAmountFunded;
  address private immutable i_owner;
  AggregatorV3Interface private s_priceFeed;

  modifier onlyOwner() {
    // require(i_owner == msg.sender, "You cannot withdraw as you are not the owner of this contract");
    if (msg.sender != i_owner) {
      revert FundMe__notOwner();
    }
    _;
  }

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  // receive() external payable {
  //   fund();
  // }

  // fallback() external payable {
  //   fund();
  // }

/**
 *  @notice This function funds this contract
 *  @dev This implements price feeds as our library
 *  
 */
  function fund() public payable {
    require(
      msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
      "Didn't send enough!"
    );
    s_funders.push(msg.sender);
    s_addressToAmountFunded[msg.sender] = msg.value;
  }

  function withdraw() public onlyOwner {
    for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
      address funder = s_funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0);

    //transfer
    // payable(msg.sender).transfer(address(this).balance);

    //send
    // bool sendSuccess = payable(msg.sender).send(address(this).balance);
    // require(sendSuccess, "Send failed");

    //call
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call failed");
  }

  function cheaperWithdraw() public payable onlyOwner{
    address[] memory funders = s_funders;
    for(uint i = 0; i < funders.length; i++){
      address funder = funders[i];
      s_addressToAmountFunded[funder] = 0;
    }
    s_funders = new address [](0);
    (bool success, ) = i_owner.call{value: address(this).balance}("");
    require(success);
  }

  function getOwner()public view returns(address){
    return i_owner;
  }

  function getFunders(uint256 index)public view returns(address){
    return s_funders[index];
  }

  function getAddressToAmountFunded(address funder) public view returns(uint){
    return s_addressToAmountFunded[funder];
  }

  function getPriceFeed() public view returns(AggregatorV3Interface){
    return s_priceFeed;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        //ABI
        // //Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        (,int256 price,,,) = priceFeed.latestRoundData();
        //ETH in USD
        return uint256(price * 1e10); //1**10 == 10000000000
    }

    // function getVersion() internal view returns (uint256){
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    //     return priceFeed.version();
    // }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd  = (ethPrice * ethAmount) / 1e18;
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