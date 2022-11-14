//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "PriceConverter.sol";

error NotOwner(); //Custom Error

contract FundMe {
    using PriceConverter for uint256;
    // constant and immutable are gas savers
    uint256 public constant MIN_USD = 50 * 1e18;
    address public immutable owner;

    address[] public funders;
    mapping(address => uint256) public addressToAmt;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MIN_USD, "Didnt send enough"); //1e18 = 1*10^18 = 1ETH
        funders.push(msg.sender);
        addressToAmt[msg.sender] = msg.value;
        // 18 decimals
    }

    function withdraw() public onlyOwner {
        // For loop
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmt[funder] = 0;
        }
        // reset an array
        funders = new address[](0);

        // withdraw eth

        // 1. transfer
        // msg.sender => address
        // payable(msg.sender) => payable address
        // payable(msg.sender).transfer(address(this).balance);

        // 2. send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");

        // 3. call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == owner, "Not the owner");
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
// 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice() internal view returns (uint256) {
        // ABI, Address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // uint8 dec = priceFeed.decimals(); // 8 decimals
        return uint256(price * 1e10);
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmt) internal view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmtInUsd = (ethPrice * ethAmt) / 1e18;
        return ethAmtInUsd;
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