// Get funds from users
// Withdraw funds
// Set a minimum funding value in BUSD

// What is reverting?
// undo any action before, and send remaining gas back

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PriceConverter.sol";

// 836,759 with constant
// 856,349 without constant

error NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 20 * 1e18; // 1 * 10 ** 18
    // 21,415 gas - constant
    // 23,515 gas - non-constant
    // 21,415 * 15000000000 = $0.335 = INR 26.45
    // 23,515 * 15000000000 = $0.368 = INR 29.05

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    // Owner
    address public /* immutable */ owner;
    // 21508 gas - immutable
    // 23644 gas - non-immutable 

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract?
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough!"); // 1e18 == 1 * 10 ** 18 == 1000000000000000000
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Sender is Not the owner");
        /* starting index, ending index, step amount */
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            // code
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the array
        funders = new address[](0);
        
        // actually withdraw the funds


        // transfer
        // msg.sender = address
        // payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);
        
        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed!");

        // call
        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner {
        // require(msg.sender == owner, "Sender is Not the owner");
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    // What happens if someone sends this contract ETH without calling
    // the fund function
    
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI
        // Address of contract 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000
        return uint256(price * 1e10); // 1e10 == 10000000000
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 1033_000000000000000000 = ETH / USD price
        // 1_000000000000000000 ETH
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getDecimals() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.decimals();
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