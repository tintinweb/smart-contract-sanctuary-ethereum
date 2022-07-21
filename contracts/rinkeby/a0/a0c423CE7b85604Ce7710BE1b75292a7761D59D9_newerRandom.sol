/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title newerRandom
 * @dev Each time get new random in interval
 */
contract newerRandom {
  uint256 constant inclusiveUpperBorder = 5;
  uint256 constant inclusiveLowerBorder = 1;
  mapping(uint256 => uint256) recorded;
  uint256 nextIndex = inclusiveLowerBorder;

  uint256 public generatedNumber;

  function getNextRandom() public returns (uint256 _randomNumber) {
    require(nextIndex <= inclusiveUpperBorder, "Used every index");
    if (nextIndex < inclusiveUpperBorder) {
      uint256 rand = (uint256(
        keccak256(
          abi.encodePacked(
            block.timestamp,
            blockhash(block.number - 1),
            msg.sender,
            nextIndex
          )
        )
      ) % (inclusiveUpperBorder - nextIndex + 1)) + nextIndex;
      _randomNumber = recorded[rand] > 0 ? recorded[rand] : rand;
      generatedNumber = _randomNumber;
      recorded[rand] = recorded[nextIndex] > 0
        ? recorded[nextIndex]
        : nextIndex;
      nextIndex++;
    } else {
      generatedNumber = recorded[nextIndex] > 0
        ? recorded[nextIndex]
        : nextIndex;
      _randomNumber = generatedNumber;
      nextIndex++;
    }
  }
}