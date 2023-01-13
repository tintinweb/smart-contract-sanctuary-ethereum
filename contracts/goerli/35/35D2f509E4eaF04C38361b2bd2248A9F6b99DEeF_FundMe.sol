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

pragma solidity ^0.8.0;

import './PriceConverter.sol';

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_COINS = 5 * 10 ** 18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        // .getConversionRate 第一个参数由msg.value直接提供，可以不用写出
        require(msg.value.getConversionRate(s_priceFeed) > MINIMUM_COINS, "Not enough coins to send!"); // 1e18 = 1 * 10 ** 18
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withDraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex ++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the array
        funders = new address[](0);

        // actually withdraw the funds

        // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "send failed");

        // call
        // (bool callSuccess, bytes dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        // require(callSuccess, "call failed");

    }

    modifier onlyOwner {
        require(msg.sender == owner, "Sender is not owner!");
        // if (msg.sender != owner) {
        //     revert  NotOwner();
        // }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256){
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    // call it get fiatConversionRate, since it assumes something about decimals
    // It wouldn't work for every aggregator
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}