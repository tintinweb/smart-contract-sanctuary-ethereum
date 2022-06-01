// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol"; // importing library
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// custom errors
error NotOwner();

contract FundMe {
    using PriceConverter for uint256; // mapping library to any type

    uint256 constant MIN_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmtFunded;
    AggregatorV3Interface public priceFeed;

    address public immutable i_owner;

    // Constructor
    constructor(AggregatorV3Interface priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Didn't send enough!!"
        );

        funders.push(msg.sender);
        addressToAmtFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            addressToAmtFunded[funders[i]] = 0;
        }
        funders = new address[](0);

        // transfer amount to sender

        (bool res, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );

        require(res, "Failed!!!");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner,"Not the owner!!!"); (this is before v0.8)
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // fallback & receive

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
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