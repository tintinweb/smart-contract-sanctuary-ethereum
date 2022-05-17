/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

pragma solidity ^0.6.7;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

contract PriceConsumer {

    AggregatorInterface internal priceFeed;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() public {
        priceFeed = AggregatorInterface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }
  
    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        return priceFeed.latestAnswer();
    }

    /**
     * Returns the timestamp of the latest price update
     */
    function getLatestPriceTimestamp() public view returns (uint256) {
        return priceFeed.latestTimestamp();
    }
}