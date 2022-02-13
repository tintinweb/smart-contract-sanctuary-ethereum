// SPDX-License-Identifier: MIT
// version: 4-test
// github.com/toprakkeskin
pragma solidity ^0.8.0;

contract WishingWell {
  
  event OnNewWish (WishType indexed _type, address indexed _sender, uint256 _timestamp, string _message);
  enum WishType { Candle, Star, Coin }
  uint256 candles;
  uint256 stars;
  uint256 coins;
  uint256 oldestWishesInView; // block.number
  uint256[10] lastWishes; // [block.number]

  constructor() payable {
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
    shiftWishView(block.number);
    emit OnNewWish(_type, msg.sender, block.timestamp, _message);
    uint256 prizeAmount = 0.0001 ether;
    require(
      prizeAmount <= address(this).balance,
      "Trying to withdraw more money than the contract has."
    );
    (bool success, ) = (msg.sender).call{value: prizeAmount}("");
    require(success, "Failed to withdraw money from contract.");
    
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

  function getOldestWishInView() public view returns (uint256) {
    return oldestWishesInView;
  }

  function shiftWishView(uint256 _newBlockNumber) private {
    uint8 ind = uint8(lastWishes.length);
    for(uint8 i=0; i < lastWishes.length; i++) {
      if (lastWishes[i] == 0) {
        ind = uint8(i);
        break;
      }
    }
    if (ind == 0) {
      oldestWishesInView = _newBlockNumber;
    }
    if (ind >= uint8(lastWishes.length)) {
      oldestWishesInView = lastWishes[1];
      for(uint8 i=0; i < lastWishes.length-1; i++) {
        lastWishes[i] = lastWishes[i+1];
      }
      lastWishes[lastWishes.length-1] = _newBlockNumber;      
    } else {
      lastWishes[ind] =_newBlockNumber;
    }
  }
}