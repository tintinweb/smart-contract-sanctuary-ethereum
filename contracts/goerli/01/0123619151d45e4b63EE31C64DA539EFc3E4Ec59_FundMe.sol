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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Imports the Price converter and attach to uint256

import "./PriceConverter.sol";

error FundMe__NotOwner();

// interfaces, libraries, contracts

/** @title A contract for crowd funding
 * @author Shawn Esquivel
 * @notice This contract demos a sample funding contract
 * @dev This implements price feeds as our library
 */

contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;
    uint256 public constant MIN_USD = 0.02 * 1e18;

    // modifier - extract one line to a single keyword
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not the owner!!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // do the rest of the code, must be BELOW require
    }

    // gets called immediately w hen you run FundMe
    constructor(address priceFeedAddress) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        i_owner = msg.sender; //whoever deploys the contract
    }

    // Special functions - 1 max - receive() & fallback()
    // Not Essential
    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    /**
     * @notice This function funds this contract
     * @dev This implements price feeds as our library
     */
    function fund() public payable {
        // to get the $ amount -> msg.value;

        // Use decentralized oracle net (ChainLink) to convert USD to ETH

        // 1*10^18 gwei = 1 ETH
        // require (getConversionRate(msg.value) >= MIN_USD, "Did not reach min. 1ETH fund");
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Did not reach min. 1ETH fund"
        );

        // revert - undoes any actions and sends gas back
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset array
        funders = new address[](0);

        // withdraw funds
        // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // call -
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Sorry the call failed");

        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Sorry, the send failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// attach a library

library PriceConverter {
    // 1. functions are all internal
    // 2. cannot have state variables
    // 3. cant send ether
    // We could make this internal, but then we'd have to deploy it
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Goerli ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate is in 18 digit
        return uint256(answer * 1e10);
        // or (Both will do the same thing)
        // return uint256(answer * 1e10); // 1* 10 ** 10 == 10000000000
    }

    // convert msg.value to dollars
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Get the price in ETH/USD
        uint256 ethPrice = getPrice(priceFeed); // usd/eth
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
        return ethAmountInUsd;
    }
}