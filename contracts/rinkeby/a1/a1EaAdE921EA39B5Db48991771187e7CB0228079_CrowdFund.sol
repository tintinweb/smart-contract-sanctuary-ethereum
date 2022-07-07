// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// Error

error CrowdFund__NotOwner();

// Contract

contract CrowdFund {
    // type initializer
    using PriceConverter for uint256;

    // data types
    uint256 private constant MIN_AMOUNT = 50;
    address private immutable owner;

    // storage data types (computationaly expensive)

    address[] private funders;
    mapping(address => uint256) private balances;

    AggregatorV3Interface private priceFeed;

    // Modifiers

    modifier OnlyOwner() {
        if (owner != msg.sender) {
            revert CrowdFund__NotOwner();
        }
        _;
    }

    // Constructor

    constructor(address addressArgument) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(addressArgument);
    }

    // getter functions

    function getOwner() public view returns (address) {
        return owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return funders[index];
    }

    function getAmountFundedByTheAddress(address funder)
        public
        view
        returns (uint256)
    {
        return balances[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }

    // functions

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_AMOUNT,
            "You need to spend more funds."
        );
        funders.push(msg.sender);
        balances[msg.sender] += msg.value;
    }

    function withDraw() public payable OnlyOwner {
        address[] memory fundersCopy = funders;

        for (uint256 index = 0; index < fundersCopy.length; index++) {
            address funder = fundersCopy[index];
            balances[funder] = 0;
        }

        funders = new address[](0);

        // verification

        (bool callSuccess, ) = owner.call{value: address(this).balance}("");
        require(callSuccess, "call failed");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// importing libraries
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Library

library PriceConverter {
    //functions

    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 amount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 price = getPrice(priceFeed);
        uint256 ethAmoutInUSD = (price * amount) / 1000000000000000000;
        return ethAmoutInUSD;
    }
}