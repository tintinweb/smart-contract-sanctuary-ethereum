// SPDX-License-Identifier: MIT

// Pragma
pragma solidity ^0.8.0;

// Imports
import "./PriceConverter.sol";

// Error Codes
error FundMe__NotOwner();

// Interfaces

// Libraries

// Contracts
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    uint256 public constant minimumUSD = 50 * 1e18;
    address public owner;
    AggregatorV3Interface public s_priceFeed;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    // Events

    // Modifiers
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Not Owner");
        if (msg.sender != owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    //Functions

    // Constructor
    constructor(address priceFeed) {
        //i_owner = msg.sender;
        owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    // recieve function
    receive() external payable {
        fund();
    }

    // fallback function
    fallback() external payable {
        fund();
    }

    // external

    // public
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= minimumUSD,
            "SEND AT LEAST 50 USD"
        );

        addressToAmountFunded[msg.sender] = msg.value;
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

        funders = new address[](0);

        // There are three ways to transfer ether:
        // 1. transfer
        // 2. send
        // 3. call

        // For transfer, we need to type cast:
        // msg.sender = address
        // (payable)msg.sender = payable address
        // returns an error if it failed, unlike send
        //payable(msg.sender).transfer(address(this).balance);

        // For send, we need to type cast also similar to transfer
        // bool isSendSuccess = payable(msg.sender).send(address(this).balance);
        //require(isSendSuccess, "Send Failed");

        // For call
        (bool isCallSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(isCallSuccess, "Call Failed");
    }
    // internal

    // private

    // view / pure
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // We need the ABI of the contract
        // Address from Chainlink "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e"
        
        //No need
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //    0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //);

        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        //

        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 etherAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 etherPrice = getPrice(priceFeed);
        uint256 ethereAmountInUSD = (etherPrice * etherAmount) / 1e18;

        return ethereAmountInUSD;
    }
}

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