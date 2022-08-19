// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

// constant, imumtable  = saves gas

// 858,213  immutable and constant set
// 901,635  non immutable and non constant

error NotOwner();

contract FundMe {
  using PriceConverter for uint256;

  uint256 public constant MINIMUM_USD = 5 * 1e18;
  address[] public funders;
  mapping(address => uint256) public addressToAmountFunded;

  address public immutable i_owner;

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  // Contract address: 0x4089e13ac92b61c8b1a657a58691a8507e8a0904
  function fund() public payable {
    //} returns (bool){
    // set a minimum fund amount in USD
    // 1. How do we send ETH to this contract
    // require(msg.value >= 1e18, "Didn't send enough"); //1e18 == 1 * 10 ** 18 == 1000000000000000000 == 1 ETH

    //msg.value.getConversionRate();
    require(
      msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
      "Value provided is too low. Increase Value and retry"
    );
    funders.push(msg.sender);
    addressToAmountFunded[msg.sender] = msg.value;

    //address payable toSendTo = payable(0xC72Bfc829cf1Ed7AC1388A8f0394262ED01385B1);

    //return toSendTo.send(msg.value / 2);
  }

  function withdraw() public onlyOwner {
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      addressToAmountFunded[funder] = 0;
    }

    funders = new address[](0);

    // transfer
    // payable(msg.sender).transfer(address(this).balance);     // throws error is exceeds 2300 gas

    // send
    // bool sendSuccess = payable(msg.sender).send(address(this).balance);     // returns false is exceeds 2300 gas
    // require(sendSuccess, "Send failure");

    // call
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }(""); // returns false is exceeds provided gas
    require(callSuccess, "Send failure");
  }

  modifier onlyOwner() {
    if (msg.sender != i_owner) {
      revert NotOwner();
    }
    // require(msg.sender == i_owner, "Sender is not owner");
    _; // run code after onlyOwner
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
  // We could make this public, but then we'd have to deploy it
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    // Rinkeby ETH / USD Address
    // https://docs.chain.link/docs/ethereum-addresses/
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    // ETH/USD rate in 18 digit
    return uint256(answer * 10000000000);
  }

  // 1000000000
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