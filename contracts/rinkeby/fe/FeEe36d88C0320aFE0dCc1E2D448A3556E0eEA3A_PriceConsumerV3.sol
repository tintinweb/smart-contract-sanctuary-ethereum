/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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

/**
 * @title The PriceConsumerV3 contract
 * @notice Acontract that returns latest price from Chainlink Price Feeds
 */
contract PriceConsumerV3 {
  AggregatorV3Interface internal immutable priceFeed;
  // increments positions that are open
  uint64 public lastPositionId = 0;


  /**
   * @notice Executes once when a contract is created to initialize state variables
   *
   * @param _priceFeed - Price Feed Address
   *
   * Network: Rinkeby
   * Aggregator: ETH/USD
   * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
   */

  // units in EUR because its EUR USD
  // negative -1 is shorting one euro
  // If margin/size are positive, the position is long; if negative then it is short.
    struct Position {
        uint64 id;
        uint64 lastFundingIndex;
        uint128 margin;
        uint128 lastPrice;
        int128 size;
    }

  mapping(address => Position) public positions;
  /// mapping of position id to account addresses
  mapping(uint => address) public positionIdOwner;


  constructor(address _priceFeed) {
    priceFeed = AggregatorV3Interface(_priceFeed);
  }

  /**
   * @notice Returns the latest price
   *
   * @return latest price
   */
  function getLatestPrice() public view returns (int256) {
    (
      uint80 roundID,
      int256 price,
      uint256 startedAt,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    return price;
  }

  /**
   * @notice Returns the Price Feed address
   *
   * @return Price Feed address
   */
  function getPriceFeed() public view returns (AggregatorV3Interface) {
    return priceFeed;
  }

  function trade(int128 newsize) external returns (bool) {
    address sender = msg.sender;
    Position storage position = positions[sender];
    Position memory oldPosition = position;
    uint64 id;
    if (position.id == 0) {
      lastPositionId++;
      id = lastPositionId;
      positionIdOwner[id] = sender;
    } else {
      id = position.id;
    }
    //position.id = id;

    uint256 price = uint256(getLatestPrice() * 10**10);
    Position memory newPosition = 
      Position({
        id: id,
        lastFundingIndex: 0,
        margin: uint128(10),
        lastPrice: uint128(price),
        size: int128(int(oldPosition.size) + newsize)
      });
    position.margin = newPosition.margin;
    position.id = id;
    position.size = newPosition.size;
    position.lastPrice = newPosition.lastPrice;
    position.lastFundingIndex = newPosition.lastFundingIndex;

    return true;

  }


  // function _formatAggregatorAnswer(bytes32 currencyKey, int256 rate) internal view returns (uint) {
  //   require(rate >= 0, "Negative rate not supported");
  //   if (currencyKeyDecimals[currencyKey] > 0) {
  //       uint multiplier = 10**uint(SafeMath.sub(18, currencyKeyDecimals[currencyKey]));
  //       return uint(uint(rate).mul(multiplier));
  //   }
  //     return uint(rate);
  // }

}

// sample margin of eth
//3250 309 191 767 340 759 697

// size in eth
//28 451 647 612 489 290 000

// price of eth
//1894 120 000 000 000 000 000

// notional value
//54 066 381 441 537 272 894 100

// accessible margin
//1261 265 024 344 699 541 960

// remaining margin
//3423 494 927 375 233 769 581

// og deposited margin
// 3400 486 553 063 044 181 687