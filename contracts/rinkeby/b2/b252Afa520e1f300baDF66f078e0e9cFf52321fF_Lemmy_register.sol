/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lemmy_register{
  uint256 public max = 1000;
  uint256 public registred_count;
  mapping(address => bool) public isRegistred;

  function register_address() public {
    require(bool(isRegistred[msg.sender])==false, "Address is already registred");
    require(uint256(registred_count)<uint256(max), "Register max is already reached");
    registred_count += 1;
    isRegistred[msg.sender] = true;
  }
  function ifRegistred(address addr) public view returns(bool){
    return isRegistred[addr];
  }
}