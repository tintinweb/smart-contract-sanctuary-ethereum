// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.7;

// 576.825 gas cost

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using StateConverter for uint256;
    uint256 constant MIN_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public AdrressToAmountFunded;
    address public immutable i_OWNER;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_OWNER = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Not enough money"
        );
        funders.push(msg.sender);
        AdrressToAmountFunded[msg.sender] = msg.value;
        // Get ETH => USD conversion rate
    }

    function withdraw() public OnlyOwner {
        // Resetting mapping
        for (
            uint256 funderIndex = 1;
            funderIndex < funders.length;
            funderIndex++
        ) {
            AdrressToAmountFunded[funders[funderIndex]] = 0;
        }
        // Resetting Array
        funders = new address[](0);
        // Withdrawing funds

        // call
        (bool SendSuccess, bytes memory DataReturned) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(SendSuccess, "Withdrawal failed");
    }

    modifier OnlyOwner() {
        if (msg.sender != i_OWNER) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library StateConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 Ethprice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (Ethprice * ethAmount) / 1e18;
        return ethAmountInUsd;
        // Adrress 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // ABI
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