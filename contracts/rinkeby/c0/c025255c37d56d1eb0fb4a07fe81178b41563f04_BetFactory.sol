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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Bet {
    AggregatorV3Interface public priceFeed;
    int256 public strikePrice;
    uint256 public expiry;
    uint256 public odds;
    address public writer;
    bool public writerOver;
    address public taker;

    /// @notice thrown when writer tries to perform actions only possible before start
    error BetIsLive();

    /// @notice thrown when taker tries to take too small or too big position
    error FundingError();

    error BetInProgress();
    error Unauthorized();
    error FailedEtherTransfer();
    error BetNotStarted();

    constructor(address priceFeedAddress, int256 _strikePrice, uint256 _expiry, 
                uint256 _odds, bool _writerOver, address _writer) payable {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        strikePrice = _strikePrice;
        expiry = _expiry;
        odds = _odds;
        writerOver = _writerOver;
        writer = _writer;
    }

    function withdraw() public {
        if (taker != 0x0000000000000000000000000000000000000000) revert BetIsLive();
        if (msg.sender != writer) revert Unauthorized();

        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        if (!sent) revert FailedEtherTransfer();
    }

    function takeBet() public payable {
        if (msg.value != address(this).balance / 2) revert FundingError();
        if (msg.sender == writer) revert Unauthorized();
        taker = msg.sender;
    }

    function getLatestPrice() public view returns (int256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        return price;
    }

    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function claimReserves() public {
        if (taker == 0x0000000000000000000000000000000000000000) revert BetNotStarted();
        if (block.timestamp < expiry) revert BetInProgress();

        (,int256 price,,,) = priceFeed.latestRoundData();
        bool overStrikePrice = price > strikePrice ? true : false;
        address winner = writerOver == overStrikePrice ? writer : taker;
        if (msg.sender != winner) revert Unauthorized();

        // we are after expiry and determined who's the winner
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        if (!sent) revert FailedEtherTransfer();
        
    }
}

contract BetFactory {

    /// @notice thrown when user tries to create bet without funding it
    error NoFunding();

    mapping (uint256 => Bet) public getBet;

    /// @notice Used as a counter for the next bet index.
	uint256 public betId = 0;

    function createBet(address priceFeedAddress, int256 strikePrice, uint256 expiry, 
                        uint256 odds, bool over) public payable returns (Bet) {
        if (msg.value <= 0) revert NoFunding();
        Bet betContract = new Bet{value: msg.value}(priceFeedAddress, strikePrice, 
                                                    expiry, odds, over, msg.sender);
        getBet[betId++] = betContract;
        return betContract;
    }
}