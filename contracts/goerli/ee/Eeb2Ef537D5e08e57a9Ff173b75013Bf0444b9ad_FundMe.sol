// This contract is meant to get funds from users
// withdraw funds
// set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    // constant can be added to this global vriable at the top after the public keword to reduce the gas fee for calling the minUsd


    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable owner;
    // immutable keyword before the owner variable and changing the owner variable to i_owner, reduces the gas fee for calling the i_owner variable

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // The payable keyword makes the public fund function red and not orange
        // contract addresses can hold funds also just like wallet addresses
        require(msg.value.getConversionRate(priceFeed) > MINIMUM_USD, "You didn't send enough funds.");
        // based on the code above, if the amount of eth sent isn't greater than 1 eth,
        // the function/contract execution is reverted
        // reverting means that the action is undone and the gas fees are returned
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public {
        // to loop through the entire array of funders,
        // we need to specify a starting index number/point, 
        // an ending index number/point and 
        // the step number or the increament for the looping.
        // how to do the above is put below
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // to actually withdraw from the contract we need to
        // reset the array
        funders = new address[](0);
        // then we actually withdraw funds.

        // three ways to withdraw funds are through the options //transfer //send //call
        // for the transfer option
        // payable(msg.sender).transfer(address(this).balance);
        // //for the send option
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed!");
        // for call optiion/command
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
        // using the call command is the recommended way to send or receive eth from a native blockchain
    }

    modifier onlyOwner {
        // require(msg.sender == i_owner, "Sender is not owner");
        if(msg.sender != owner) revert FundMe__NotOwner();
        _;

    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256){
        
        (,int price,,,) = priceFeed.latestRoundData();
        // the int price needed and called above can be positive or negative and thats why int is used
        // the price called will give us the equivalent of ETH in usd
        return uint256(price * 1e10);
    }

    function getVersion() internal view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
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