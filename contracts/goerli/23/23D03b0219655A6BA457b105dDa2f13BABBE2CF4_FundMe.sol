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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//GetFunds from users
//Withdraw funds
//Set a minimum funding value in USD

import "./PriceConverter1.sol";

contract FundMe {
    //make it public bcoz we want everybody can call this function
    //Want to be able to set a minimum fund amount in USD
    //1. How do we send ETH to this contract
    //keyword "payable" makes the button to red color

    using PriceConverter1 for uint256;

    uint256 public minimumUsd = 50 * 1e18; //1 * 10 ** 18

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender; //where msg.sender is whomever deployed the contract
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //"require" set minimum of price
        //If first section below is false, then revert the error message followed by
        //revert means undo any action before, and send remaining gas back
        //number = 8;
        //require(msg.value > 1e18, "Didn't send enough!"); //1e18 == 1 * 10 ** 18 == 1000000000000000000 == 1ETH
        require(
            msg.value.getConversionRate(priceFeed) >= minimumUsd,
            "Didn't send enough!"
        ); //1e18 == 1 * 10 ** 18 == 1000000000000000000 == 1ETH 18 decimals
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        //user modifier to make sure the ownership is checked before reading the content of the function
        //require(msg.sender == owner, "Sender is not the owner!"); // == means checking two variables are equivilant
        //for loop
        //[1,2,3,4]
        //0. 1. 2. 3. looping turn
        /*starting index, ending index, step amount */
        //e.g. 0, 10, 2 that means 0 2 4 6 8 10
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset the array
        funders = new address[](0); //reset to 0 as a brand new array
        //actually withdraw the funds

        //transfer

        //msg.sender = address
        //payable(msg.sender) = payable address
        //payable (msg.sender).transfer(address(this).balance);  //keyword "this" means this whole contract

        //send
        //bool sendSuccess = payble(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send failed");

        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); //can call other contracts' function
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the owner!"); // == means checking two variables are equivilant
        _; //_; means process the rest of code
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter1 {
    function getPrice(
        AggregatorV3Interface priceFeed
    )
        internal
        view
        returns (
            uint256 // ABI
        )
    // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e).version //call version function on the contract specified
    //AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //    0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData(); //return whole bunch of variable of the lastestRoundData function under AggregatorV3Interface
        //remove other variable to get only the price of ETH in terms of USD //3000.00000000
        return uint256(answer * 1e10); //1**10 == 10000000000
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        //3000_000000000000000000 = ETH/ USD price
        //1_000000000000000000 ETH
        uint ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}