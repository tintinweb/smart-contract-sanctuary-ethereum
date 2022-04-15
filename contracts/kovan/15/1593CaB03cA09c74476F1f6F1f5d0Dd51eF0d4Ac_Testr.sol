// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Testr {
  address public admin;
  event LogErrorString(string message);

  constructor() {
    // type of msg.sender is address payable
    admin = msg.sender;
  }

  function error1() external payable {
    require(false, "only admin");
  }

  function error2() external payable {
    emit LogErrorString("external call failed!");
  }
}