/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;


contract Test{
  constructor(){}

  function c() public payable returns(uint256){
      return msg.value*(0.20*10**9);
  }
}