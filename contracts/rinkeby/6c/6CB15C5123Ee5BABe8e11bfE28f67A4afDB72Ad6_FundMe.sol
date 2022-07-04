// SPDX-License-Identifier: MIT

pragma solidity <=0.8.8;

import "./PriceConvertor.sol";

contract FundMe {

    using PriceConvertor for uint256;

    uint256 public constant minUsd = 5 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    AggregatorV3Interface public priceFeed;

    address public immutable i_owner;
    constructor(address priceFeedAddress){
        i_owner = msg.sender; 
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable{
        // set minimum fund amount in USD
        require(msg.value.getConversionRate(priceFeed) >= minUsd, "Didn't send enough");
        // 1e18 = 1*10 ** 18 == value of wei for 1 eth
        // msg.value will have 18 decimal places
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value; // in wei
    }

    function withdraw() public onlyOwner {
        
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++)
        {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); //reset the array

        // actually withdraw the funds
        // msg.sender = address
        // payable(msg.sender) = payable address
        // call
        (bool callSuccess, /* bytes memory dataReturned */) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }

    modifier onlyOwner {
        require(msg.sender == i_owner, "Sender is not owner");
        _;
    }

    // what happens if someone sends this contract eth without calling fund
    // receive
    // fallback

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity <=0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        uint256 ethPrice = uint256(price * 1e10); // price of 1 eth
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
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