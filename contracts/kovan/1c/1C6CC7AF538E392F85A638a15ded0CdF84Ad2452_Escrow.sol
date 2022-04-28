// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Escrow {
    // chainlink price feed
    AggregatorV3Interface internal priceFeed;

    // participants
    address public bull; // bets the price will be higher than anchor at expiration
    address public bear; // bets the price will be lower than anchor at expiration
    // parameters
    uint256 public anchorPrice; // anchor > expirationPrice --> bear and vice versa
    uint256 public wager; // the amount each party has to put up
    // timekeeping
    uint256 public initTimestamp; // timestamp the bet was initialized
    uint256 public activeTimestamp; // timestamp the bet was fully funded
    uint256 public paydayTimestamp; // payday / expiration time
    // TODO: account for one deposit made
    enum State {
        INITIALIZED,
        ACTIVE,
        COMPLETE
    } // contract state
    State public state;

    /** The constructor initializes the escrow betting contract
    address _assetPriceFeed - address of the chainlink datafeed
    int256 _anchorPrice - the high or low point
    uint256 _paydayTimestamp - payday / expiration time
    */
    constructor(
        address _assetPriceFeed,
        uint256 _wager,
        uint256 _anchorPrice,
        uint256 _paydayTimestamp
    ) {
        // TODO: add parameter checks
        initTimestamp = block.timestamp;
        priceFeed = AggregatorV3Interface(_assetPriceFeed);
        wager = _wager;
        anchorPrice = _anchorPrice;
        paydayTimestamp = _paydayTimestamp;
        state = State.INITIALIZED;
    }

    // TODO: deposit functionality
    // TODO: refactor
    function bullDeposit() public payable {
        require(bull == address(0), "The bull deposit was already made.");
        require(msg.value == wager, "Must deposit wager ammount.");
        bull = msg.sender;
    }

    function bearDeposit() public payable {
        require(bear == address(0), "The bear deposit was already made.");
        require(msg.value == wager, "Must deposit wager ammount.");
        bear = msg.sender;
    }

    function showContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function sendWinnings(bool bullWins) private {
        if (bullWins) {
            payable(bull).transfer(address(this).balance);
        } else {
            payable(bear).transfer(address(this).balance);
        }
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    // TODO: checkUpkeep

    // TODO: performUpkeep

    // TODO: change state
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