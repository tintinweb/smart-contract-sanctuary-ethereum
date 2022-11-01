//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;
    //A data type is attached to the imported library

    uint256 minimumUsd = 50;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        // Constructor is a function that is immediately called when the contract is created
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress); //Creation of a smart contract variable
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= minimumUsd); /* msg.value would be the first
                                                                 parameter of getConversionRate() function */

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Sender is not owner!");
        // This is to ensure that only the owner withdraws the funds

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex += 1
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // Resetting the array
        funders = new address[](0);
        // This array is reset to a new variable address and it contains 0 elements

        // To actually send ether to the user calling it, there are three different ways used:
        // transfer
        // send
        // call

        // Using transfer
        payable(msg.sender).transfer(address(this).balance);
        // this keyword refers to the whole contract where balance is to be sent
        // this is typecasted to address as we want to tranfer the amount to this address
        /* msg.sender is typecasted to payable as:
          msg.sender is of type address
          payable(msg.sender) is of type payable address 
          */

        // Using send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send Failed");

        // transfer automatically reverts, but send needs to be manually reverted

        // Using call
        (bool callSuccess, bytes memory dataReturned) = payable(msg.sender)
            .call{value: address(this).balance}("");
        // call returns two values and bytes data type has array so memory keyword is used for function call
        // The last parenthesis refers to any function. It is blank since we are not refering to any function

        require(callSuccess, "Call failed");
        // Call is a recommended way for transfers
    }

    modifier onlyOwner() {
        /* Modifiers are functions that are used as a condition in other functions
       with the use of a keyword. They are created to re-use the same condition easily */

        require(msg.sender == owner, "Sender is not owner");
        _; // The underscore tells the function to do the rest of the code only after the above code is executed
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    /* Libraries are similar to contracts, but you can't declare any state 
   variable and you can't send ether.
   A library can be emebdded into a contract unless all library functions are internal */

    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // When an abi like AggregatorV3Interface is linked to testnet address, it becomes a smart contract

        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getVersion(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        return priceFeed.version();
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

//When address is parameterised, data feeds for any address can be viewed

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