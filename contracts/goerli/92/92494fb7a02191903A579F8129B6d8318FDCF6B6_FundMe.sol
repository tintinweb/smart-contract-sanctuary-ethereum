// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    AggregatorV3Interface internal priceFeed;
    address owner;
    address[] public founders;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        ); // ETH/USD
        owner = msg.sender;
    }

    mapping(address => uint256) public UserFunds;

    function getLatestPriceWEIUSD() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        internal
        view
        returns (uint256)
    {
        uint256 latestPrice = getLatestPriceWEIUSD();
        return (ethAmount * latestPrice) / 10**18;
    }

    function fund() public payable returns (uint256) {
        require(
            getConversionRate(msg.value) >= 20 * 10**18,
            "You need to pay at least 20 USD"
        );
        UserFunds[msg.sender] += msg.value;
        founders.push(msg.sender);
        return msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not an Owner");
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 index = 0; index < founders.length; index++)
            UserFunds[founders[index]] = 0;
        founders = new address[](0);
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