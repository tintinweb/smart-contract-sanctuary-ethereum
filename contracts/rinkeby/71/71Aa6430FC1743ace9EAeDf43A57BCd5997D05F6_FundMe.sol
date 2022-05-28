/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



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

contract FundMe{
    mapping (address => uint256) public address2Amount;

    address public owner;
    address[] public Funders;

    constructor() public{
        owner = msg.sender;
    }


    function fund() public payable {
        // more than 50 dollars
        uint256 minimum_value = 1*10*18;
        require (getConversionRate(msg.value) >= minimum_value, "not enough fund");
        address2Amount[msg.sender] += msg.value;   
        Funders.push(msg.sender);    
    }

    function getVersion() public view returns (uint256){
        AggregatorV3Interface PriceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return PriceFeed.version();
    }

    function getPrice() public view returns (uint256){

        AggregatorV3Interface PriceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        (uint80 roundId,
         int256 answer,
         uint256 startedAt,
         uint256 updatedAt,
         uint80 answeredInRound
     ) = PriceFeed.latestRoundData();
     return uint256(answer);
    }

    function getConversionRate(uint256 amount) public view returns(uint256) {
        uint256 Eth_price = getPrice();
        uint256 Usd = (amount * Eth_price)/1000000000000000000;
        return Usd;
    }

    function widthdraw() public payable {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);

        for (uint256 FunderIndex=0; FunderIndex<Funders.length; FunderIndex++){
            address Funder_address = Funders[FunderIndex];
            address2Amount[Funder_address] = 0;
        }
        Funders = new address[](0);
    }
}