/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //ประกาศเวอชั่น

contract fukinnft {
 string public Hello = "hello world";
  uint256 public token = 5000;
  uint256 public money = 300;
  //function
  function deposit(uint256 _amount) public {
    money += _amount;

  }

}