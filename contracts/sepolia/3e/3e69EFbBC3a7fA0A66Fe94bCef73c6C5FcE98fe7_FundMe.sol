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

// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT

// Pragma
pragma solidity ^0.8.8;
// Imports
import "./PriceConverter.sol";

// 794,539
// 774,997

// Error codes
error FundMe__NotOwner();

// Note: Using these Custom errors is cheaper the using require statement
// We can use "if" condition and then revert with custom error

// Interfaces, Libraries, Contracts

// Reason for these tags is
// They help creating automatic documentation
// By running the command
// solc --userdoc --devdoc ex1.sol
// 'ex1.sol' can be any file name
/**
 * @title A contract for crowd funding
 * @author Me
 * @notice This is contract is demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations

    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
    // 2451 gas - non-constant
    // 351  gas - constant

    // 'constant' assigned on the line it is declared
    // 'immutable' can be assigned later but after assignment
    // it will not change

    // 'constant' and 'immutable' does not store variable in storage
    // rather they store it in the byte code of the contract

    // State Variables
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;

    // 2580 gas - non-immutable
    // 444 gas - immutable

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
            // using this custom error instead of 'require' will help us save gas
            // as we don't need to store whole string here
        }
        _; // this means rest of the code of the function where modifier is used
    }

    // Functions Order:
    //// contructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // fallback() external payable {
    //     fund();
    // }

    // receive() external payable {
    //     fund();
    // }

    /**
     * @notice This function funds this contract
     * @dev This implements price feeds as our library
     */
    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract?
        // we don't pass it any argument as it is a first argument itself automatically
        require(
            msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD,
            "Didn't send enough!"
        ); // 1e18 = 1 * 10 ** 18 == 1000000000000000000
        // if condition in first argument isn't met then this function reverts
        // in case if it is reverted, any prior work is undone
        // gas for any computation done 'after' the require function is also returned
        // but not for computation done 'before' require function

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public payable onlyOwner {
        // withdraw need not to be payable as we are not paying any money
        // we are just receiving it

        /* starting index, ending index, step amount */
        for (
            uint256 fundersIndex = 0;
            fundersIndex < s_funders.length;
            fundersIndex++
        ) {
            address funder = s_funders[fundersIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset array
        s_funders = new address[](0);
        // actually withdraw the funds
        // transfer
        // send
        // call

        // in solidity to transfer currency we need payable address
        // msg.sender = address
        // payable(msg.sender) = payable address

        // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // 'this' means this whole contract
        // 'balance' is the balance stored in this contract

        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // it does not revert even if transation is not completed
        // hence we need 'require'
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
        // call is the recomended way of transferring ethereum or blockchain native token

        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value:address(this).balance}("");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
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
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    // Two special functions in solidity
    // receive()
    // fallback()
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ABI
        // Address 0x694AA1769357215DE4FAC081bf1f309aDC325306

        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.0000000000 it has 8 decimals but ETH has 18 decimals
        return uint256(price * 1e10); // price will have 10 more decimals

        // Note: we convert any float number into whole number
        // because in solidity decimal points can lead to errors
    }

    // AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0x694AA1769357215DE4FAC081bf1f309aDC325306
    //     );

    // Object on which this function is called is itself the first argument
    // If we need a second argument here then we will it as first arguemnt at call site
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}