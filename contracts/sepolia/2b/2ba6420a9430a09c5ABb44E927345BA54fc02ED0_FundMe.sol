//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint;

    uint public constant MINIMUM_USD = 50 * 10 ** 18;

    address[] public funders;
    mapping(address => uint) public addressToAmountFunded;
    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        owner = msg.sender;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Need More ETH!!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "sender is not owner");
        _;
    }

    function withdraw() public onlyOwner {
        for (
            uint funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        // payable(msg.sender).transfer(address(this).balance);

        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess,"Failed transction");

        (bool callSuccess /*bytes memory dataReturns*/, ) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "call failed");
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
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint) {
        (, int answer, , , ) = priceFeed.latestRoundData();
        return uint(answer * 1e18);
    }

    function getConversionRate(
        uint ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint) {
        uint ethPrice = getPrice(priceFeed);
        uint ethAmountInUsd = (ethPrice * ethAmount) / 1e18;

        return ethAmountInUsd;
    }
}