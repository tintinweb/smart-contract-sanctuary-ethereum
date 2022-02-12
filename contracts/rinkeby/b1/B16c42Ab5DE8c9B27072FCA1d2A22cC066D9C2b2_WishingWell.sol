// SPDX-License-Identifier: MIT
// version: 2
// github.com/toprakkeskin
pragma solidity ^0.8.0;

contract WishingWell {
  
  event OnNewWish (WishType indexed _type, address indexed _sender, uint256 _timestamp, string _message);
  enum WishType { Candle, Star, Coin }
  uint256 candles;
  uint256 stars;
  uint256 coins;
 
  constructor() {
  }
  
  function makeAWish(WishType _type, string memory _message) public {
    require(bytes(_message).length > 0, "Empty Message");
    if (_type == WishType.Candle) {
      assert(candles + 1 > candles);
      candles++;
    } else if (_type == WishType.Star) {
      assert(stars + 1 > stars);
      stars++;
    } else if (_type == WishType.Coin) {
      assert(coins + 1 > coins);
      coins++;
    }
    emit OnNewWish(_type, msg.sender, block.timestamp, _message);
  }

  function getTotalWishes() public view returns (uint256) {
    uint256 totalWishes = candles + stars + coins;
    return totalWishes;
  }

  function getWishCountByType(WishType _type) public view returns (uint256) {
    uint256 count = coins;
    if (_type == WishType.Candle) {
      count = candles;
    } else if (_type == WishType.Star) {
      count = stars;
    } else if (_type == WishType.Coin) {
      count = coins;
    }
    return count;
  }
}