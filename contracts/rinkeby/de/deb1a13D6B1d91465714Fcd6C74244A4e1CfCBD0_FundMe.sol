/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;

    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    // The following function is the function that we will use for funding
    function fund() public payable {
        // $50
        uint256 minimumUSD = 50 * 10**18;
        // One way to make sure of the least amount is if statement
        // if(msg.value < minimumUSD){}
        // The second way using required statement which is cleaner
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "Hello, you need to spend more ETH!!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        // What the ETH -> USD conversion rate

        // Add people to funders array
        funders.push(msg.sender);
        // If one funder funds several times, this array going to be redundant, you need to find out how to solve this?
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1000000000);
    }

    // 1000000000 Gwei
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 100000000000000000;
        // 243546093121.000000000000000000
        // 0.00000243546093121
        return ethAmountInUsd;
    }

    // How modifiers work, and to apply it to function/methods you only need to add them to their headers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // The withdraw function does not work figure it out
    // The following method will make sure that only the owner can withdraw
    // It worked in the video
    function withdraw() public payable onlyOwner {
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            // There are two ways to do the following:
            // The first way:
            // address funder = funders[fundersIndex];
            // addressToAmountFunded[funder] = 0;
            // The second way:
            addressToAmountFunded[funders[fundersIndex]] = 0;
        }
        funders = new address[](0); // Resetting the array of funders
    }

    // The balance function actually works, and it is pretty amazing
    function balance() public view onlyOwner returns (uint256) {
        return (address(this).balance);
    }

    // After even creating the owner inside the constructor, if you create a function to change the owner, you would be able to do that
    // function changeOwner() public returns(address){
    //     return owner = 0xbf45bC6B0867f2a960cE6775370EA0D5287b6dAD;
    // }
}