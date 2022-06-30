// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public fundToAddress;
    address public owner;
    address[] public funders; // this address array will contain addresses of funders

    // constructor is exeucuted the instant smart contract is deloyed
    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * 10 * 18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend ETH worth at least  50 USD"
        );
        // let's keep track of who sent us funding
        fundToAddress[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return pricefeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        //icefeed.latestRoundData();

        //(
        //   uint80 roundId,
        //   int256 answer,
        //   uint256 startedAt,
        //   uint256 updatedAt,
        //   uint80 answeredInRound
        //) =  pricefeed.latestRoundData();

        (, int256 answer, , , ) = pricefeed.latestRoundData();
        //return uint256(answer / 10 ** 8);
        return uint256(answer);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    // modifier is a function which changes behavior of a function in a declarative way
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withDraw() public payable onlyOwner {
        //require(msg.sender == owner);
        // "this" is a keyword in solidity, which referes to the contract you are in
        // address(this) --> address of the contract you are currently in
        payable(msg.sender).transfer(address(this).balance); // transfering to msg.sender

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            fundToAddress[funder] = 0;
        }

        // funders array will be initialized to zero
        funders = new address[](0);
    }

    //    function withDraw() payable public {
    //        require(msg.sender == owner);
    //        // "this" is a keyword in solidity, which referes to the contract you are in
    //        // address(this) --> address of the contract you are currently in
    //        payable(msg.sender).transfer(address(this).balance);   // transfering to msg.sender
    //    }
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