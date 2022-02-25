/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Greeter {
  string greeting;

  event SetGreeting(address sender, address origin);

  constructor(string memory _greeting) {
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    greeting = _greeting;
    emit SetGreeting(msg.sender, tx.origin);
  }
}