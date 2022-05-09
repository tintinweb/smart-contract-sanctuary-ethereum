/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: UNLICENCE

pragma solidity 0.8.10;

contract TestingEvent {
  event Story(string story);

  function testMe() external returns (string memory) {
    emit Story("Congrats");
    return "I'm done";
  }
}