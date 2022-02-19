// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";


contract FundMe {

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    // constructor is a function which gets called the instant the contract is deployed
    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        //set minimum usd value to 50$
        uint256 minimumUSD = 50 * 10 ** 18;
        require(getConversionRate(msg.value) >= minimumUSD, "Minimum 50$");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256){
        return priceFeed.version();
    }

    function getEthBalance() public view returns (uint256){
        return address(this).balance;
    }

    function getPrice() public view returns (uint256){
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getEnteranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1*10**18;
        return (minimumUSD * precision) / price;
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 usdValue = (ethPrice * ethAmount) / 1000000000000000000;
        return usdValue;
    }
    // modifiers change the behaviour of the functions 
    modifier onlyOwner{
        require(msg.sender == owner, "bro wtf you can't withdraw");
        _;
    }
    function withdraw() payable onlyOwner public {
        // require(msg.sender == owner, "bro wtf you can't withdraw");
        msg.sender.transfer(address(this).balance);
        // resetting every funder's balance to 0 after withdrawing
        for (uint256 i=0; i < funders.length; i++ ){
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
// 0.000002875540000000

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