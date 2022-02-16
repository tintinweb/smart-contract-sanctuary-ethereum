/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
  string private greeting;
  address private owner;

  constructor(address _owner) {
    owner = _owner;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    greeting = _greeting;
  }
}