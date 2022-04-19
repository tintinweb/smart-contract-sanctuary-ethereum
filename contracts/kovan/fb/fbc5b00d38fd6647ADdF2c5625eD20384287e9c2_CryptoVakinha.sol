//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "AggregatorV3Interface.sol";

contract CryptoVakinha {

    address[] public funders;
    address public owner;
    mapping(address => uint256) addressToAmountFunded;
    uint256 public totalAmountFunded = 0;
    address priceFeedEthToUsd;

    constructor(address _priceFeed) {
        owner = msg.sender;
        priceFeedEthToUsd = _priceFeed;
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * (10 ** 18);
        uint256 converted = getConversionRate(msg.value);
        require(converted >= minimumUSD, "More eth needed");
        addressToAmountFunded[msg.sender] += msg.value;
        totalAmountFunded += msg.value;
        funders.push(msg.sender);
    }


    function getVersion() public view returns (uint256) {
        AggregatorV3Interface ethToUsdFeed = AggregatorV3Interface(priceFeedEthToUsd);
        return ethToUsdFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface ethToUsdFeed = AggregatorV3Interface(priceFeedEthToUsd);
        (,int256 answer,,,) = ethToUsdFeed.latestRoundData();
        //answer returns in "gwei-dollars" and we need it in wei instead
        return uint256(answer * (10 ** 10));
        //now it returns 3040113751200000000000, which means the actual price is 3040.113751200000000000
    }

    //receives an amount in wei to convert to wei dollars
    function getConversionRate(uint256 ethWeiAmount) public view returns (uint256) {
        uint256 ethPriceInUsdWei = getPrice();
        //this will be a ridiculous number
        uint256 ethAmountInUsd = (ethWeiAmount * ethPriceInUsdWei) / (10 ** 18);

        //if I pass 1eth, it should return:
        //3040113751200000000000
        //which means 3040.113751200000000000
        //if I pass 1gwei, it should return:
        //304011375120
        //which means 3040.113751200000000000

        return ethAmountInUsd;
    }

    function toIntegerDollars(uint256 weiAmount) public pure returns (uint256) {
        return weiAmount / (10 ** 18);
    }

    //utility function that allows you to pass an amount in dollars (just the real-life usage dollar part, not wei dollars) 
    //and get the amount of eth wei it represents
    function dollarsToWei(uint256 dollarAmount) public view returns (uint256) {
        uint256 weiDollars = dollarAmount *  (10 ** 18); //this will be 1e+18
        uint256 oneEthInWeiDollars = getPrice(); //this will be 2394e18
        
        //if we simply divide them one by the other (weiDollars / oneEthInWeiDollars), integer division could result in 0 if we pass like 2 dollars.
        //so we find first a multiplication that gives us a big (huge) number, and then divide later
        //we basically add zeros first, do math, and them divide later
        //we do that by multiplying by the wei unit again 
        uint256 dollarsInEthWei = (weiDollars * (10 ** 18)) / oneEthInWeiDollars;
        //the division will get rid of the 10**18 extra we multiplied.

        //notice that:
        //(weiDollars * (10 ** 18)) / oneEthInWeiDollars
        //is the same as
        //(weiDollars / oneEthInWeiDollars) * (10 ** 18)
        //but we don't have the integer division problem

        return dollarsInEthWei;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public {
        for (uint256 i = 0; i < funders.length; i++) {
            delete addressToAmountFunded[funders[i]];
        }
        delete funders;
        totalAmountFunded = 0;
        payable(msg.sender).transfer(address(this).balance);
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