/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


contract Test{
  uint256 public data;  
  constructor(){

  }

  function c() public payable returns(uint256){
      data=(msg.value*(0.05*10**9))/10**9;
      return data;
  }
}