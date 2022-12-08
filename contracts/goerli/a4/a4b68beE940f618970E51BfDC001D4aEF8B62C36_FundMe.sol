// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "AggregatorV3Interface.sol";
import "AggregatorV3Interface.sol";

contract FundMe {

    // using keywork can be used to check integer overflow , 
    // using SafeMathChainlink for uint256; <-- syntax
    mapping (address => uint256 ) public addressToAmountFunded ; // a mapping of address of the funder and the amount funded 

    address[] public funders; // an array of the funders address , filtered from the mapping above

    address owner;
    constructor () public {
        owner = msg.sender;
    }

    function getOwner() public view returns(address) {
        return owner;
    }
    function fund() public payable {

        uint256 minimumAmountToFund = 50 * 10 ** 18 ; 

        require ( getConversionRate(msg.value) >= minimumAmountToFund, "Not enough amount !, more ETH"); // check the funding amount to the minimum amount to fund 

        addressToAmountFunded[msg.sender] += msg.value; // a payable function to fund a given amount
        funders.push(msg.sender);
    }

    function getPrice () public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

        (,int256 answer,,,) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000);
    }

    function getConversionRate (uint256 ethAmount ) public view returns(uint256) {
        // uint gweiAmount = msg.value * getPrice();

        return uint256(ethAmount * getPrice() / 1000000000000000000); // ethAmountInUSD


    }

    // modifer : acts as a middleware for a function 
    modifier onlyOwner {
        require (msg.sender == owner); 
        _; // continue executing code 
    }

    function withdraw() payable onlyOwner public {

        payable(msg.sender).transfer(address(this).balance); // transfer all the balance in this contract to the caller of this function 

        for(uint256 i= 0; i<funders.length; i++){ // loop through the funders array, grab the funders address , empty the value stored in the mapping ( address => balance ) for the address
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[] (0); // resetting the funder address

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