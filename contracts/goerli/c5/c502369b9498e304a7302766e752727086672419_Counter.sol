// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract Counter{

  uint public counter;
  address public owner;

  constructor(uint x){
    counter = x;
    owner = msg.sender;
  }

  function count() public {
    require(msg.sender == owner,"only owner is allowed!");
    counter += 1;
  }

}