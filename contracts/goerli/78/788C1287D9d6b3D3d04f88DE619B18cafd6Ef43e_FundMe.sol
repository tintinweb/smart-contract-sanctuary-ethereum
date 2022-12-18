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

// importing contracts/modules from github directly
import "./PriceConverter.sol";

error NotOwner();

// Get funds from user
// Withdraw funds
// Set a min funding value in USD
contract FundMe {
    // This attaches PriceConverter library to uint256..
    using PriceConverter for uint256;

    // constant because it is set once outside any function and never set again
    uint256 public constant MIN_USD = 50 * 1e18;

    address[] public funder;
    mapping(address => uint256) public addressToAmount;

    // immutable if value is set by a function once and is never changed afterwards
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    // contructor gets called immediatly called once contract is deployed..
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // "payable" keyword makes possible to hold funds..
    function fund() public payable {
        // ensure min values sent is 1 ETH.
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Didn't send enough"
        ); // 1 ETH = 10^18 Wei..
        // If this require condition is unmet, then any changes done before it will be undone
        // and any extra gas is returned.

        funder.push(msg.sender);
        addressToAmount[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // checks if sender is owner for able to withdraw funds.. Better way to check this is modifiers..
        // require(msg.sender == owner, "Sender is not contract owner. Action not allowed");

        for (
            uint256 funderIndex = 0;
            funderIndex < funder.length;
            funderIndex = funderIndex + 1
        ) {
            address funderAddress = funder[funderIndex];
            addressToAmount[funderAddress] = 0;
        }

        // reset the funders array..
        funder = new address[](0);

        // send ETH from contracts..
        // 3 ways to do this

        // 1. Transfer
        payable(msg.sender).transfer(address(this).balance);
        // transfer function has a gal limit of 2300..
        // If it execeds, transaction failes and automatically reverts tx with error..

        // 2. Send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");
        // send also has gas limit of 2300, but does not throw error, rather returns bool value
        // manual check and reverting is required in this case..

        // 3. Call
        (bool callSuccess, bytes memory dataReturned) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
        // call does not have any gas limit, rather this is a generic call to call any function of
        // any contract even without its ABI.. it returns a boolean and bytes data..
        // Manual check and revertign of tx is required in this case..
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not contract owner. Action not allowed");

        // to make contract gas efficient..
        if (msg.sender != i_owner) {
            revert NotOwner();
        }

        _; // this represents doing rest of the code..
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Since working outside of the chainlink smart contract, we'd need
        // ABI, Address --> 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        // Working with interfaces is basically getting the ABI for the contract..
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );

        // price of ETH in USD
        (, int price, , , ) = priceFeed.latestRoundData();

        return uint256(price * 1e10); // because price has decimals of 1e8.. to match with Wei, include 1e10 into it..
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // math reference here -->
        // getPrice() -> 3000.000000000000000000 (18 decimals)
        // ethAmount  -> 1000000000000000000 Wei(18 decimals)
        return (ethAmount * getPrice(priceFeed)) / 1e18;
    }
}