// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./priceConvertor.sol";

contract FundMe {
    using priceConvertor for uint256;

    uint256 constant MINIMUM_USD = 10 * 1e18;
    address[] private funders;
    mapping(address => uint256) private addressToAmountFunders;
    address immutable i_owner;
    AggregatorV3Interface private priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fundMe() public payable {
        require(
            msg.value.getConversion(priceFeed) > MINIMUM_USD,
            "didn't send enough"
        );
        funders.push(msg.sender);
        addressToAmountFunders[msg.sender] += msg.value;
    }

    function withdraw() public only_owner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunders[funder] = 0;
        }

        funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call fail");
    }

    modifier only_owner() {
        require(msg.sender == i_owner, "function caller is not owner");
        _;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library priceConvertor {
    function getPrice(
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 answer, , , ) = _priceFeed.latestRoundData();
        return uint256(answer * 1e10);
        // 174555037974
    }

    function getConversion(
        uint256 _amount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        uint256 ethAmount = getPrice(_priceFeed);
        uint256 ethAmountUsd = (_amount * ethAmount) / 1e18;
        return ethAmountUsd;
    }
}