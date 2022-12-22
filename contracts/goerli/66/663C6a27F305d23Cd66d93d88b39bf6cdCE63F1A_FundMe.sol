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

pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint;
    uint public constant MIN_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint) public addressToAmountFunded;

    address public immutable owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= MIN_USD, "Didn't send enough!!");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;    
    }

    function withdraw() public onlyOwner{
        // require(msg.sender == owner, "Sender is not the owner!!"); // this line has been commented because I will be using a modifier described at the end of this function.

        for(uint funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);  // this line is to reset the array. the value in the curly brackets indicate the number of items in the newly created array.

        // // three ways to send money in a smart contract
        // // 1. transfer
        // payable(msg.sender).transfer(address(this).balance); // typecasting the msg.sender to a payable address. 'this' refers to the current contract. gives an error and reverts the txn if more than 2300 gas is used, which means that the txn has failed.

        // // 2. send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance); // here, 'send' returns a boolean value if more than 2300 gas is used. we can use this bool value in a 'require' statement to verify whether the txn was successful or not.
        // require(sendSuccess, "Send failed!!");

        // 3.call --> lower level command
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");  // this function is basically used to call another function. returns two items, hence the comma. returns a callSuccess, and a data object in bytes format.
        require(callSuccess, "Call failed!!");
    }


    // modifiers are basically like middlewares
    modifier onlyOwner {
        // require(msg.sender == owner, "Sender is not the owner");
        if(msg.sender != owner)
            revert NotOwner();
        _;  // '_' means that carry on with the rest of the function.
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 price, , ,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint ethPrice = getPrice(priceFeed);
        uint ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
    }
}