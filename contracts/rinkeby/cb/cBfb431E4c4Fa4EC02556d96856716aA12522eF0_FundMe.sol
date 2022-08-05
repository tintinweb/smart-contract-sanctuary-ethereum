//SPDX-License-Identifier: MIT

//pragma
pragma solidity 0.8.7;

// imports
import "./Library.sol";

// error code
error FundMe_NotOwner();

/// @title A contract for the funding
/// @author Rakshith kumar s
/// @notice this contract is to demo the smaple funding contract
contract FundMe {
  using PriceConverter for uint256;

  address[] public senders;

  uint256 public constant MINIMUN_USD = 1 * 1e18;
  mapping(address => uint256) public addressToValue;

  address public immutable owner;

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  // modifier are used to check the prerequisites for the function
  // if it contains all the prerequisites, then it will the function
  // else it will throw the error
  modifier onlyOwner() {
    require(msg.sender == owner, "you are not the owner");
    _; // _ is used to continue the th function
  }

  function fundme() public payable {
    require(
      PriceConverter.getConverstionRate(msg.value, priceFeed) > MINIMUN_USD,
      "don't enough fund"
    );
    senders.push(msg.sender);
    addressToValue[msg.sender] = msg.value;
  }

  function withDraw() public onlyOwner {
    for (uint256 funderIndex = 0; funderIndex < senders.length; funderIndex++) {
      address senderAddress = senders[funderIndex];
      addressToValue[senderAddress] = 0;
    }
    senders = new address[](0);

    // payable(msg.sender).transfer(address(this).balance);
    // bool snedFail = payable(msg.sender).send(address(this).balance);
    // require(snedFail , "send Failes");

    (
      bool callSuccess, // bytes memory dataReturn

    ) = payable(msg.sender).call{value: address(this).balance}("");
    require(callSuccess, "call failed");
  }

  receive() external payable {
    fundme();
  }

  fallback() external payable {
    fundme();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    // AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    // );
    (
      ,
      /*uint80 roundID*/
      int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
      ,
      ,

    ) = priceFeed.latestRoundData();
    return uint256(price * 1e10);
  }

  function getConverstionRate(
    uint256 ethAmount,
    AggregatorV3Interface priceFeed
  ) internal view returns (uint256) {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
    return ethAmountInUsd;
  }

  // function getVersion() internal view returns (uint256) {
  //     //ABI
  //     //Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
  //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
  //         0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
  //     );
  //     return priceFeed.version();
  // }
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