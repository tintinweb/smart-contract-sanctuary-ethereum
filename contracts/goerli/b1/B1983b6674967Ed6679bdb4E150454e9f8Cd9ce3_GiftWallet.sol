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
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// import "hardhat/console.sol";

contract GiftWallet {
    AggregatorV3Interface internal priceFeed;

    address public owner;
    uint256 public constant MINIMUM_USD = 11 * 1e18; // send in Wei
    uint256 public constant SERVICE_COST_USD = 10 * 1e18; // send in Wei

    constructor(address _aggregator) {
        priceFeed = AggregatorV3Interface(_aggregator);
        owner = msg.sender;
    }

    event GiftResponse(bool success, bytes data);

    modifier onlyOwner() {
        require(owner == msg.sender, "Sender is not owner");
        _;
    }

    function getPrice() private view returns (uint256) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Call failed");
    }

    function getConversionRate(
        uint256 _ethAmount
    ) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    // function getGiftTokens(uint256 value) private view returns (uint256) {
    //     return getConversionRate(value) - SERVICE_COST_USD;
    // }

    function gift(address _giftAddress) public payable {
        require(
            getConversionRate(msg.value) > MINIMUM_USD,
            "Require at least 11 dollars"
        );
        uint256 totalPrice = msg.value - SERVICE_COST_USD;
        (bool success, bytes memory data) = _giftAddress.call{
            value: totalPrice
        }("");
        require(success, "Failed to send Ether");

        emit GiftResponse(success, data);
    }

    receive() external payable {}

    fallback() external payable {}
}