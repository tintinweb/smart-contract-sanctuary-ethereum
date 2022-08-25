// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PriceConvertor} from "./PriceConvertor.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NotOwner();

contract FundMe {
    using PriceConvertor for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    // 	21393 gas -> contant
    //   23493 gas  -> without constant

    address[] public funders;
    mapping(address => uint256) public addressToAmtDonated;

    address public immutable i_owner;

    // 	21486 gas -> immutable
    // 23493 gas -> without immutable

    AggregatorV3Interface public priceFeed; // to hold the priceFeed contract, done so that we can modularise the code wrt thepriceFeed based on chains since each chain will have differnet priceFeed contract address

    constructor(address priceFeedAddress) {
        i_owner = msg.sender; // The person deploying the contract is the owner
        priceFeed = AggregatorV3Interface(priceFeedAddress); // Initializing the price feed with the contract , since when we provide the interface with the contract address we get the contract instance
    }

    function fund()
        public
        payable
    // payable allows txn initiators to send ether to this smart contract's function
    {
        //  For setting 1eth as min fund value:
        require(
            msg.value.getConversion(priceFeed) >= MINIMUM_USD,
            "Donated amt must be atleast 1 eth!"
        ); // 1e18 == 1 * 10 ** 18 i.e 10^18
        // msg.value-> is the field that contains / stores the value field of the txn
        funders.push(msg.sender); // Pushing the funder's account address , msg.sender -> contains the address of the account that initiated the txn
        addressToAmtDonated[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // We want only the person who deployed the contract to withdraw and not just anyone

        // Loop through the funders array and , set the amt donated to 0 for each since we are withdrawing
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmtDonated[funder] = 0; // Setting it to 0 since we have withdrwan , the amt
        }
        //  reset funders array
        funders = new address[](0); // i.e now funders points to a new address array with 0 elements
        // Transer the ether to the owner

        // transfer
        // payable(msg.sender).transfer(address(this).balance); // address.transfer(amtOfEther);
        // send
        // bool success= payable(msg.sender).send(address(this).balance); // address.send(amtOfEther);
        // require(success,"Send Failed, Transfer of ether failed");
        // call
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Failed to send Ether");
    }

    modifier onlyOwner() {
        // require(msg.sender==i_owner,"Sender is not owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _; // _ -> rperesnets the function body
    }

    // What happens when someone sends ETH to the contract without using the fund (which is payable) function.
    receive() external payable {
        // Whenever someone sends plain Eth without having any call data then receive will get executed
        //  and we'll call the fund() function
        fund();
    }

    fallback() external payable {
        //  Whenever somonse sends Eth to contract , but txn has call data and not other function signature matches
        // then fallback will get executed , and we'll call the fund() function
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // function to get the current usd price from Oracle i.e chain link
        //  Since for this we are interacting with another contract ( Aggregator contract , which has variable storing current usd price of ethereum )
        //  So we'll need the
        // 1] ABI of that contract
        // 2] Contract Address 0xA39434A63A52E749F02807ae27335515BA4b07F7 ( On Goreli)
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xA39434A63A52E749F02807ae27335515BA4b07F7
        // );
        (
            ,
            //  uint80 roundId
            int256 answer, //  uint256 startedAt //  uint256 updatedAt //  uint80 answeredInRound
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(answer * 1e10); // Since asnwer of price of ETH IN usd HAS 8 decimal places , while value sent to contract has 18 decimal places hence muiplied by 10^10 so both 18 deciaml places
    }

    // Taking priceFeed contract as parameter since we do not want to hardcode the address of the priceFeed contract, and want it to be flexible wrt the chain
    function getConversion(uint256 ethAmt, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 price = getPrice(priceFeed); // Getting the price of ethereum in USD
        uint256 ethAmtInUsd = (ethAmt * price) / 1e18;
        return ethAmtInUsd;
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