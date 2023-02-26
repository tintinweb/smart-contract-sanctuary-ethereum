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

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

// deploy: 856181
// after adding constant and immutable: 811668
// after adding constant, immutable and custom error

contract FundMe {
    using PriceConcerter for uint;

    uint256 constant MIN_AMOUNT = 50 * 1e18;

    address[] public funders;
    mapping(address => uint) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);

    }

    function fund() payable public {
        uint256 amountInUsd = msg.value.getExchangeRate(priceFeed);
        require(amountInUsd <= MIN_AMOUNT, "Don't be a cheap ass!!");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for(uint funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed!");
    }

    modifier onlyOwner(){
        // require(msg.sender == i_owner, "Only owner has the privilidge to do this");
        if (msg.sender != i_owner) { revert NotOwner(); }
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

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConcerter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint) {
        // address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // ABI from chainlink interface import
        (,int price,,,) = priceFeed.latestRoundData();
        return uint(price * 1e10);
    }

    function getExchangeRate(uint eth, AggregatorV3Interface priceFeed) internal view returns(uint) {
        uint ethValueInUsd = getPrice(priceFeed);
        uint usd = (ethValueInUsd * eth) / 1e18;
        return usd;
    }
}