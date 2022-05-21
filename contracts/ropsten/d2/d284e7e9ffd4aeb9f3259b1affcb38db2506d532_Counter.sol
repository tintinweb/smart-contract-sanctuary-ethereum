/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Counter{
  uint public _state = 0;
  function state() public view returns (uint){
    return _state;
  }
  function increment() public {
    _state += 1; 
  }
  function decrement() public {
    require(_state >= 0, "You cannot decrement more");
    _state -= 1;
  }
}