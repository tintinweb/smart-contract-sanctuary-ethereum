// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint constant MIN_USD = 50 * 1e18;

    address[] public founders;
    mapping(address => uint256) public addressToAmountFounded;

    address public immutable i_owner;
    AggregatorV3Interface public immutable priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Not enougth"
        );
        founders.push(msg.sender);
        addressToAmountFounded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint i = 0; i < founders.length; i++) {
            addressToAmountFounded[founders[i]] = 0;
        }
        founders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed!");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
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
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    address constant ETH_USD = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;

    function getPrice(AggregatorV3Interface priceFeed)
        private
        view
        returns (uint256)
    {
        (, int price, , , ) = priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function getConversionRate(uint ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        return (getPrice(priceFeed) * ethAmount) / 1e18;
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