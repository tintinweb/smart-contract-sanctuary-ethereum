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

//Get funds from users
//Withdraw funds
//Set a min funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";
//import "hardhat/console.sol"
//allows console.log() for debugging

error FundMe__NotOwner();
error FundMe__Insufficient();
error FundMe__CallFailed();

//NatSpec
/**
 * @title A contract for crowd funding
 * @author AB
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */

contract FundMe {
    //Type Declarations
    using PriceConverter for uint256;

    //State Variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    //constant, immutable => reduce gas used,
    //does not take up storage spot, can be used if the value does not, will not change
    //typical ALL CAPS

    address[] private s_funders;
    mapping(address => uint256) private s_addresstoAmountFunded;

    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    //Events
    //no events for this contract

    //Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        } //save gas
        //require(msg.sender == i_owner, "Sender is not owner!"); //do this first
        _; //then do the rest of the code of the function inserted
    }

    //constructor gets deployed when the contract is deployed, in the same transaction
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //what happens if someone sends this contract ETH without using fund function
    // special functions => receive, fallback
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds this contract
     * @dev asdfg
     */

    function fund() public payable {
        //wants everybody to be able to fund
        // require(
        //     msg.value.getConverstionRate(s_priceFeed) >= MINIMUM_USD,
        //     "Insufficient"
        // );
        if (msg.value.getConverstionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__Insufficient();
        }
        //msg.value; //to get how much value someone is sending
        //require(getConverstionRate(msg.value) >= MINIMUM_USD, "Insufficient"); //set to a min value //1e18 == 1*10**18 == 1000000000000000000 = 1ETH
        //18decimals
        s_funders.push(msg.sender);
        s_addresstoAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        //require(msg.sender == owner, "Sender is not owner!");
        //inserted as modifier to be used in all functions requiring this statement

        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addresstoAmountFunded[funder] = 0;
        }
        //reset the array to make it a blank array
        s_funders = new address[](0);

        //withraw: transfer / send / call => commonly used: call

        //transfer
        //msg.sender = address
        //payable(msg.sender) = payable address
        //payable(msg.sender).transfer(address(this).balance);

        //send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send failed");

        //call
        //(bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        //require(callSuccess, "Call failed");
        if (!callSuccess) {
            revert FundMe__CallFailed();
        }
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        //mappings cant be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addresstoAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        //require(success);
        if (!success) {
            revert FundMe__CallFailed();
        }
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addresstoAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//This is a library
//functions in libraries are internal

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ABI
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //     );
    //     return priceFeed.version();
    // }

    function getConverstionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; //multiply and add first before divide in Solidity
        return ethAmountInUsd;
    }
}