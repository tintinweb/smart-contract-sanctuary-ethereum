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

  error InsufficientBalance(string message);

  function error2() external payable {
    //   revert("Only exact payments!");
    assert(1 >= 2);
  }

    function error3() external payable {
    //   revert("Only exact payments!");
    revert InsufficientBalance("description");
  }
}