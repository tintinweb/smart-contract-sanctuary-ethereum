// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

contract FundMe {
    // * library
    using PriceConverter for uint256;

    // * minimum amount require for fund.
    uint256 public constant MINIMUM_USD = 50 * 1e18; // convert to wei.

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner; // solhint-disable-line

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // the fund value should be greater than 1 ETH.
        // msg.value comes in wei.
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Insuffcient Funds!"
        ); // 1e18 is equal to 1 ETH. 1 * 10 ** 18 = 1000000000000000000 wei;
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            // get each funder.
            address funder = funders[i];
            // set amount to 0.
            addressToAmountFunded[funder] = 0;
        }

        // reset the funders array.
        funders = new address[](0);

        // * withdraw funds.
        (bool callSuccess, ) = payable(msg.sender).call{ // solhint-disable-line
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed!");
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not an owner!");
        _;
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

// * get the latest price of ETH from chainlink data feed.
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // * Aggregator address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;

        (, int256 price, , , ) = priceFeed.latestRoundData();

        // price will contains the 8 zeros, multiply with 1e10 so it can become 1e18.
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // * because of multiplication, the result will contains 36 zeros that's why divide the result with 1e18.

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