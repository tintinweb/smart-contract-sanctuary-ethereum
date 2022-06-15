// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./PriceConverter.sol";

// 872912
// 832603
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_ETHER = 1 ether;
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable owner;

    AggregatorV3Interface public priceFeed;

    error Unauthorized();

    constructor(address priceFeed_) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeed_);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    function fund() public payable {
        // Minimum aomunt in USD
        // require(msg.value >= MINIMUM_ETHER, "MINIMUM 1 ETHER REQUIRED");
        // msg.value is having 18 decimals
        // require(getConversionRate(msg.value) >= MINIMUM_USD, "MINIMUM 50 USD");

        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "MINIMUM_50_USD"
        );

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public payable onlyOwner {
        // Checks, effects .. interactions

        // Reset State Variables
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

        // withdray funds

        // transfer
        // payable(msg.sender).transfer(address(this).balance); // if this line fails, revert the state and return error object. No gas is refunded

        // send
        // bool success = payable(msg.sender).transfer(address(this).balance); // if this line fails, returns the boolean. No gas is refunded
        // require(success, "send failed")

        (bool success, bytes memory data) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "CALL_FAILED");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Chainlink Data Feeds
        // ABI
        // Address 0x9326BFA02ADD2366b30bacB125260Af641031331
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x9326BFA02ADD2366b30bacB125260Af641031331
        // );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        // price is going to have 8 decimal places
        return uint256(price * 1e10); // 1**10 = 10000000000
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0x9326BFA02ADD2366b30bacB125260Af641031331
    //     );
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 3000_000000000000000000 = ETH / USD Price
        // 1_000000000000000000 = ETH

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