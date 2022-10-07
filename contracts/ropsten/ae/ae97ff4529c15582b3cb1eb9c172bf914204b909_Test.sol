/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


contract Test{
  uint256 public data;
  uint256 private percentage=5;  
  constructor(){

  }

  function c() public payable returns(uint256){
      data=(msg.value*percentage)/10**9;
      return data;
  }


  function setPercentage(uint256 per) public {
      percentage=per;
  }


  function getPercentage() public view returns(uint256){
      return percentage;
  }
}