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

/*
1. People will send you cryptocurency in terms of USD
    a. Make a payable function to recieve ether
    b. A function to get the USD value of ether
        i. Importing AggregatorV3Interface from github
    c. A function to convert ether to its USD equivalent
2. Only you can Withdraw it
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;
import "./PriceConverter.sol";

error notOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 50 * 1e18;
    address public immutable i_owner;
    uint256 amount_rcvd;
    address[] public funders;
    mapping(address => uint256) public funded;

    AggregatorV3Interface public priceFeed;

    //Assign the owner as the address deploying the contract
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //Called when a funder sends fund to smart contract
    function fund() public payable {
        //Condition to receive a minimum amount
        amount_rcvd = msg.value.getConversionRate(priceFeed);
        require(amount_rcvd >= MIN_USD, "Minimum amount you can send is $50");
        //storing address of funder in an array
        funders.push(msg.sender);
        //Mapping the total amount to funder using funded mapper
        funded[msg.sender] += amount_rcvd;
    }

    function withdraw() public onlyOwner {
        //Clearing all the fund mappings for each funder
        for (uint i = 0; i < funders.length; i++) {
            address funder = funders[i];
            funded[funder] = 0;
        }

        //Resetting the array
        funders = new address[](0);

        //Withdrawing funds from smart conract.There are three ways:
        //1. Transfer
        //payable(msg.sender).transfer(address(this).balance);
        //2. Send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess,"Send Failed");
        //3.Call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner() {
        //Checking if the withdraw function is called by the owner
        //require(msg.sender == i_owner,"You are not the owner");
        if (msg.sender != i_owner) {
            revert notOwner();
        }
        //Running the rest of the code
        _;
    }

    // If someone directly send you fund, they will be redirected to fund() using below functions.
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //Getting the price of ethereum
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //Getting the latest price of ETH in USD
        (, int256 price, , , ) = priceFeed.latestRoundData();

        //price = 1000_00000000
        return uint256(price * 1e10);
        //price is in terms of USD multiplied by 10^10
        //price = 1000_000000000000000000
        //As solidity is not compatible with decimal, we make the decimals(received amount) = decimals(ETH in USD)
    }

    //Converting the ethereum into USD
    function getConversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        //ethPrice=1000000000000000000000; ethAmount(in wei)=50000000000000000
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18;
        //ethAmountInUsd = 50000000000000000000 ($50)
        return ethAmountInUsd;
    }
}