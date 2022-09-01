/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

//import './ethernaut.sol';
//    owner =  payable(address (msg.sender));

contract TestHarness {
  address payable public owner;
  //Fallback public obj;
  uint256 public uiNow;
  uint256 public uiNow2;
  uint public numb=23;

  constructor() public {
    owner =  payable(address (msg.sender));
    uiNow = block.timestamp;
    uiNow2 = uiNow + 3 days;

    //obj = new Fallback();

    //owner = obj.owner();

  }
  function showit() public {
        numb = 789;
  }

}