// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConsumerV3.sol";

error NotOwner();

contract FundMe {
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    PriceConsumerV3 internal priceConsumer;
    address private immutable i_owner;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    constructor(address _priceFeedAddress) {
        priceConsumer = new PriceConsumerV3(_priceFeedAddress);
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        // require(msg.sender == getOwner(), "Sender is not the owner!");
        if (msg.sender == getOwner()) {
            revert NotOwner();
        }
        _;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function fund() public payable {
        require(priceConsumer.getConversionRate(msg.value) >= MINIMUM_USD, "Didn't send enough money");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value; 
    }

    function withdraw() external onlyOwner {
        // set the amount to zero of addressToAmountFunded addresses
        for (uint256 i = 0; i < funders.length; i+=1) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        // Reset the funders array
        funders = new address[](0);

        // Transfer the balance to message sender
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract PriceConsumerV3 {
    using PriceConverter for AggregatorV3Interface;

    AggregatorV3Interface internal priceFeed;

    constructor(address _priceFeedAddress) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function getLatestPrice() public view returns (uint256) {
        return priceFeed.getLatestPrice();
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.getVersion();
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        return priceFeed.getConversionRate(ethAmount);
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
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getDecimals(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        return priceFeed.decimals();
    }

    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 decimalsLeft = uint256(18) - getDecimals(priceFeed);
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price) * 10 ** decimalsLeft;
    }

    function getVersion(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        return priceFeed.version();
    }

    function getConversionRate(AggregatorV3Interface priceFeed, uint256 ethAmount) internal view returns (uint256) {
        uint256 ethPriceInUSD = getLatestPrice(priceFeed);
        uint256 ethAmountInUSD = (ethAmount * ethPriceInUSD) / 1e18;
        return ethAmountInUSD;
    }
}