// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe{

    mapping (address => uint256) public addressToAmountFunded;
    address[] public funders;
    AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }


    function fund() public payable{
        uint256 minimumUSD = 50*10**18;

        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value; 
        funders.push(msg.sender);

    }

    function GetTotalFund() public view returns(uint256){
        uint256 total = 0;

        for(uint256 idx; idx < funders.length; idx++){

            total += addressToAmountFunded[funders[idx]];
        }

        return total;

    }

    function getVersion() public view returns(uint256){

        return priceFeed.version();
    
    }

    function getPrince() public view returns(uint256){
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
        // 2444.79010872
  
    }

    function getConversionRate(uint dolar_value) public view returns(uint256){
        uint eth_price = getPrince();
        uint256 eth_amount_in_usd =((10**18)*dolar_value/eth_price);
        return eth_amount_in_usd; 
    
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function withdraw() payable onlyOwner public {
        owner.transfer(address(this).balance);
        address address_aux;

        for (uint256 idx = 0; idx < funders.length; idx++ ){

            address_aux = funders[idx];
            addressToAmountFunded[address_aux] = 0;
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