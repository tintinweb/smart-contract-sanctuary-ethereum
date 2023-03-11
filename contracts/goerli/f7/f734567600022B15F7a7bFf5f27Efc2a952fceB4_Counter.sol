/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract Counter {
  uint public counter;
  address owner;

  constructor(uint x) {
    counter = x;
    owner = msg.sender;
  }

  function count() public {
    require(owner == msg.sender, "you can't do it.");
    counter += 1;
    // console.log("now counter is ", counter);
  }
}