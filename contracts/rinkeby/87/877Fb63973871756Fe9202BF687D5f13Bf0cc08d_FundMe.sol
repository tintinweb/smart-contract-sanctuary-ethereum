// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

    error NotOwner();

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import './PriceConverter.sol';


// Get funds from users
// Withdraw funds
// Set a minimum value in USD

contract FundMe {
    using PriceConverter for uint;
    uint public constant MINIMUM_USD = 10;
    // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    address[] public funders;
    address owner;
    uint public priceInUsd;
    mapping(address => uint) public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;

    constructor (address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // require(msg.sender == owner, 'Sender is not owner');
        // priceInUsd = getPrice();
        // uint ethToUsd = getConversionRate(msg.value);
        require(msg.value.getConversionRate(priceFeed) / 1e18 >= MINIMUM_USD, "Didn't send enough");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

//    function getPrice() public view returns (uint) {
//        //ABI
//        //Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
////        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
//        (, int price,,,) = priceFeed.latestRoundData();
//        return uint(price * 1e10);
//    }
//
//    function getVersion() public view returns (uint) {
////        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
//        return priceFeed.version();
//    }
//
//    function getConversionRate(uint ethAmount) internal view returns (uint) {
//        uint ethPrice = getPrice();
//        uint ethAmountinUsd = (ethPrice * ethAmount) / 1e18;
//        return ethAmountinUsd;
//    }

    function withdraw() public onlyOwner {
        for (uint funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset funders Array
        funders = new address[](0);
        // withdraw funds
        //        payable(msg.sender.transfer(address(this).balance));
        //        bool success = payable(msg.sender.send(address(this).balance));
        //        require(success, 'Send failed');
        (bool callSuccess,) = payable(msg.sender).call{value : address(this).balance}('');
        require(callSuccess, 'call failed');
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    modifier onlyOwner() {
        if (msg.sender != owner)
            revert NotOwner();
        // require(msg.sender == i_owner);
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

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';


library PriceConverter {
    function getVersion(AggregatorV3Interface price_feed) internal view returns (uint) {
//        AggregatorV3Interface price_feed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return price_feed.version();
    }

    function getPrice(AggregatorV3Interface price_feed) internal view returns (uint) {
//        AggregatorV3Interface price_feed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int price,,,) = price_feed.latestRoundData();
        return uint(price * 1e10);
    }

    function getConversionRate(uint ethAmount, AggregatorV3Interface price_feed) internal view returns (uint) {
        uint ethPrice = getPrice(price_feed);
        uint ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}