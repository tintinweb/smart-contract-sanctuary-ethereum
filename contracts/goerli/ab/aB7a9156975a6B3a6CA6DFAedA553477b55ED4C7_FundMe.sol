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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PriceConverter.sol"; // Library

// custom errors
error NotOwner();
error NotEnoughMoneySent();
error TransferFailed();

contract FundMe {
    using PriceConverter for uint256; // using library.

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address payable public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = payable(msg.sender); // setting owner of the contract.
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    address[] public funders; // holds address of account who calls fund function.

    mapping(address => uint256) public addressToAmount;

    function fund() public payable {
        //require(msg.value.getConversionRate() >= MINIMUM_USD, "not enough money");
        if (msg.value.getConversionRate(priceFeed) < MINIMUM_USD) {
            revert NotEnoughMoneySent();
        }

        funders.push(msg.sender);
        addressToAmount[msg.sender] += msg.value; // mapping address to amount sent.
    }

    function withdraw() public onlyOwner {
        // resetting map
        for (uint256 i = 0; i < funders.length; i++) {
            addressToAmount[funders[i]] = 0;
        }

        // resetting array
        funders = new address[](0);

        // withdraw fund
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        //require(callSuccess, "Failed");
        if (!callSuccess) {
            revert TransferFailed();
        }
    }

    // only owner modifier
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Not Owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // these functions catch the eth which is sent not using fund function and redirect to fund function
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // get price of ETH in terms of USD
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData(); // Current ETH price in USD
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return ((ethAmount * getPrice(priceFeed)) / 1e18); // return ethAmount in usd
    }
}