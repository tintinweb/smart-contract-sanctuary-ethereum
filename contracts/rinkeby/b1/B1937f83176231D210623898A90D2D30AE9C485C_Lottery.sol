//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract Lottery {
    uint256 public constant entranceFeeUSD = 50;

    address[] public players;
    address public recentWinner;
    //To remember owner of contract (for Admin only functions)
    address public owner;

    //To track lotter state
    enum LOTTERY_STATE {
        OPEN,
        CLOSE,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    AggregatorV3Interface priceFeed;

    constructor(address _priceFeedAddress) {
        lottery_state = LOTTERY_STATE.CLOSE;
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    //To check actual entrance fee in wei
    function getEntranceFee(uint256 _usdPrice) public view returns (uint256) {
        //50*10^(8+18)/3000*10^8 to have answer in wei
        (, int256 conversionRate, , , ) = priceFeed.latestRoundData();
        return (_usdPrice * 10**26) / uint256(conversionRate);
    }

    //To see number of participants
    function getPlayersNumber() public view returns (uint256) {
        return players.length;
    }

    function enter() public payable lotteryOpen {
        require(
            msg.value >= getEntranceFee(entranceFeeUSD),
            "Not enough ETH to enter!"
        );
        players.push(msg.sender);
    }

    function startLottery() public lotteryClose onlyOwner {
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public lotteryOpen onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        uint256 winnerNumber = calculateWinner();
        recentWinner = players[winnerNumber];
        payable(recentWinner).transfer(address(this).balance);
        players = new address[](0);
        lottery_state = LOTTERY_STATE.CLOSE;
    }

    function calculateWinner() internal pure returns (uint256) {
        return 0;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only admin is allowed to do this operation"
        );
        _;
    }

    modifier lotteryOpen() {
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "Lottery should be started"
        );
        _;
    }

    modifier lotteryClose() {
        require(
            lottery_state == LOTTERY_STATE.CLOSE,
            "Lottery should be finished"
        );
        _;
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