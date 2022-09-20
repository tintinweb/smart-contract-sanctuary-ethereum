// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol"; // import a interface (similar to java) 

contract FundMe {

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    constructor() {
        owner = msg.sender; 
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * 10 ** 18;
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend 50$ in ETH");
        addressToAmountFunded[msg.sender] += msg.value; // Sum all the eth funded
        // What the ETH -> USD conversion rate
        funders.push(msg.sender);
    }

    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (uint80 roundId,
        int256 answer, 
        uint256 startedAt,
        uint256 updatedAt,
        uint80 asweredInRound) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    // Do the dame as the laters, but oprimized
    function getPriceBetter() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10**18);
    }

    // Do the conversion
    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 price = getPriceBetter();
        uint256 ethAmountInUsd = (price * ethAmount) / 10**18;
        return ethAmountInUsd; 
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    function withdraw() payable onlyOwner public { // Put heare modifer, and when any push the withdraw button do the modifier validation
        // Only want the contract admin/owner
        // require(msg.sender == owner); its not needed if you have a modifier onlyOwner (declared upper)
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 i = 0; i < funders.length; i ++) { // Reset all the funder who have currently participated
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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