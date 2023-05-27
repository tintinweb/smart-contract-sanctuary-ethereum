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

//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.18;

import "./PriceConverter.sol";

// constant and immutable keywords

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // add constant to save gas
    uint256 public  constant MINIMUM_USD = 10 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // want to be able to set a minimum fund amount in USD
        // how do we send ETH to this contract

        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "didnt sent enough");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
        // what is reverting
        //undo any action before, and send remaining gas abck
    }

    function withdraw() public onlyOwner{

        require(msg.sender == i_owner, "sender is not owner");
        // for loop 
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //resetting the array
        funders = new address[](0);

        // actually withdraw the funds
        // // three ways to send ether, transfer, send, call
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send, won't revert if theres no require following
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "send failed");
        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "send failed");
        
    }

    modifier onlyOwner{
        require(msg.sender == i_owner, "sender is not owner");
        if(msg.sender != i_owner){revert NotOwner();}
        _;
    }

    receive() external payable {
        fund();
    }

    fallback()external payable{
        fund();
    }
}

//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        // ABI  
        // address for sepolia, eth to  0x694AA1769357215DE4FAC081bf1f309aDC325306

        // use chainlink interface to get the address of the sepolia eth
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        // price could be negative
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        // ETH interms of USD
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount,  AggregatorV3Interface pricefeed) internal view returns(uint256){
        uint256 ethprice = getPrice(pricefeed);
        uint256 ethAmountInUsd = (ethprice * ethAmount) / 1e18;

        return ethAmountInUsd;
    }

}