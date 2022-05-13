/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: Lottery.sol

contract Lottery {
    address payable[] public players;
    int256 public usdEntryFee;
    AggregatorV3Interface internal priceFeed;

    constructor(address _priceFeedAddress) public {
        usdEntryFee = 50 * (10**8);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function enter() public payable {
        require(msg.value > 10);
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (usdEntryFee / price);
    }

    function startLottery() public {}

    function endLottery() public {}
}