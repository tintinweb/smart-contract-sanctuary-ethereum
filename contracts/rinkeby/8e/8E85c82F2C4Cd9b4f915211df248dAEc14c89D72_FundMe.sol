//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    
    mapping(address => uint256) public addressToAmountFunded;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUsdValue = 50; // $50
        require(getConversionRate(msg.value) >= minimumUsdValue, "You need to spend more ETH");
        
        addressToAmountFunded[msg.sender] += msg.value;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        require(msg.sender == owner, "Sender is not the contract's owner");
        payable(msg.sender).transfer(address(this).balance);
    }

    function getVersion() public view returns (uint256) {
        // DataFeed na rede Rinkeby
        AggregatorV3Interface priceFeed = 
            AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // DataFeed na rede Rinkeby
        AggregatorV3Interface priceFeed = 
            AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        (,int256 answer,,,) = priceFeed.latestRoundData();

        return uint256(answer);
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethUsdPrice = getPrice();
        uint256 convertedToUsd = (ethUsdPrice * ethAmount) / 1000000000000000000;
        return convertedToUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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