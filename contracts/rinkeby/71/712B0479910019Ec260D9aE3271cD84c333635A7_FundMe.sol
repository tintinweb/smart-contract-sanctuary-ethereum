/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

/*
 Interfaces compile to ABI (Application Binary Interface)
 ABI tells how can interact with anothea contract.
 Always need an ABI to interact with a contract.
*/

contract FundMe {
    address ethToUsdPriceFeedAddress =
        0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    address public owner;
    address[] public foundersArray;

    mapping(address => uint256) public addressToAmountFunded;

    // Constructor
    constructor() public {
        owner = msg.sender;
    }

    // payable modifier -> this function can be used to pay for things.
    function fund() public payable {
        // msg.value -> number of wei sent with the message
        // msg.sender -> sender of the message

        // $50 usd
        uint256 minimumUSD = 10 * (10**18);
        uint256 value = getConvertionRate(msg.value);
        require(
            value > minimumUSD,
            "You need to spend more ETH! Minimum: 50 USD"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        foundersArray.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            ethToUsdPriceFeedAddress
        );
        return priceFeed.version();
    }

    // Get ETH (wei) -> USD conversion rate
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            ethToUsdPriceFeedAddress
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    function getConvertionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    // Used to change the behaviour of a function on a
    // declarative way. (Like middleware)
    modifier onlyOwner() {
        // require msg.sender = owner of this contract
        require(
            owner == msg.sender,
            "You're not the owner of this smart contract."
        );
        // _; indicates run the rest of the code.
        // Can be used befor or afterwords.
        _;
    }

    function withdraw() public payable onlyOwner {
        // Reserved word "this" refers to the contract
        msg.sender.transfer(address(this).balance);
        // Reset addressToAmountFunded mapping
        for (
            uint256 founderIndex = 0;
            founderIndex < foundersArray.length;
            founderIndex++
        ) {
            address founder = foundersArray[founderIndex];
            addressToAmountFunded[founder] = 0;
        }
        // Reset founders array
        foundersArray = new address[](0);
    }
}