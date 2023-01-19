// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

// This contract will accept some kind of payment
contract FundMe {

    AggregatorV3Interface internal priceFeed;
    address[] funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;

    constructor() {// constructor executes when contract is deployed
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }

    // This way contract receives money from some other address
    function fund() public payable {
        uint256 minimumUSD = 50 * 10 ** 18; // DO this to make it have 18 decimals
        require(getConversionRate(msg.value)>=minimumUSD, "You need to spend more EHT!");
        addressToAmountFunded[msg.sender] = msg.value;
        funders.push(msg.sender);
    }
    function getLatestPrice() public view returns (uint256) {        
        (,int price,,,) = priceFeed.latestRoundData();
        // we have to know that this returns number where last 8 digits are behind
        // decimal dot 154561000000 -> 1545.61000000
        //
        // To put all to GWEI standard to have 18 decimals I multiply with 10**10
        // because result has 8 decimal places
        return uint256(price)*10000000000;
        // 
    }
    function getVersion() public view returns(uint256){
        return priceFeed.version();
    }
    // 1000000000
    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getLatestPrice();

        uint256 ethAMoountInUsd = (ethPrice * ethAmount)/1000000000000000000;
        //154561000000000000000
        return ethAMoountInUsd;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _; // this is the rest of the code of the modified function
    }

    function withdraw() payable onlyOwner public{
        payable(msg.sender).transfer(address(this).balance);
        
        for (uint256 funderIndex=0; funderIndex<funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
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