//get funds from users
// withdraw funds
// set a minimum funding value in usd
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // matching values with conversion and getprice

    address[] public funders; // keep track of all funds we get
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress); 
    }

    function fund() public payable {
        // want to be able to set a min fund amt in usd
        //1. how do we send eth to this contract?
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "didnt send enough"); //=1eth in wei
        // 18 decimal places
        //above message reverts the error if occured
        //what is reverting?
        //undo any action before, and send remaining gas 
        funders.push(msg.sender); //adds address(public address) of funders to the array
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "sender is not owner");

        /* starting index, ending index, step amount */
        for( uint256 funderIndex = 0; funderIndex < funders.length; funderIndex = funderIndex ++ ) {
                address funder = funders[funderIndex];
                addressToAmountFunded[funder] = 0;
        }
        //reset the array
        funders = new address[] (0);
        // actually withdraw the funds

        // //transfer
        // //msg.sender = address
        // // payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);

        // //send
        // bool sendSuccess = payable(msg.sender).send(address(thus).balance);
        // require(sendSuccess, "send failed");

        // //call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }

    modifier onlyOwner {
        // _; putting above does the execution of function and check the condition after that
        //require(msg.sender == i_owner, "sender is not owner");
        if(msg.sender != i_owner) { revert NotOwner(); }
        _; // putting _ here checks for condition first then only executes the function
    }

    //what happens if someone sends this contract eth without calling the fund function

    receive() external payable {
        fund();
    }
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; //importing the contracts directly from github/npm.

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //abi
        //address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // eth in terms of usd
        // 1080.00000000 8 decimal places (we have to match the values with above requirement)
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
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