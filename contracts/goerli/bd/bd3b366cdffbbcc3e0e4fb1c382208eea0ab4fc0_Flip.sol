/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Flip {
  uint public count;
  address public owner;

  constructor()  {
    owner = msg.sender;
  }

  function getCount()  public view returns (uint) {
    return count;
  }

  function increment () public {
    require (msg.sender == owner, 'sender is not the owner');
    ++count;
  }

  function incrementIfOdd() public  {
    require (count % 2 != 0, 'counter not even');
    increment();
  }
}