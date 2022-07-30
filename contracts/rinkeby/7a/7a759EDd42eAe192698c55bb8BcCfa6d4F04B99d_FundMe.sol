// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

// Rinkeby: 0x7a759EDd42eAe192698c55bb8BcCfa6d4F04B99d

error NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    uint256 constant MINIMUM_USD = 10 * 1e18;
    address public immutable i_owner;

    constructor () {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        // require(i_owner == msg.sender, "Not Owner!");
        if (i_owner != msg.sender) revert NotOwner(); // custom errors  
        _; // run rest of the code
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "not enough!"); // 1e18 // wei // getConversionRate(msg.value)
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 fundersIndex = 0; fundersIndex < funders.length; fundersIndex++) {
            address funder = funders[fundersIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0); // reset array

        // sending ETH - transfer, send, call

        // payable(msg.sender).transfer(address(this).balance); // transfer
        
        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed!");

        // call
        (bool callSuccess, /* bytes memory returnedData */) = payable(msg.sender).call{value: address(this).balance}(""); // low-level
        require(callSuccess, "Call Failed!");
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

// library

library PriceConverter { 
    // gets eth / usd rate with chainlink data feed
    function getPrice() internal view returns(uint256) { // internal
        // 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e - Rinkeby
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    // converts eth to usd w/ 18 decimals
    function getConversionRate(uint ethAmount) internal view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
        return ethAmountInUsd;
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