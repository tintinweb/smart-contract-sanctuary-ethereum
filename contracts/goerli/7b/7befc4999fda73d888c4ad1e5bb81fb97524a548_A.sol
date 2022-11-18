/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 contract A {
  function a () public pure returns(string memory){
  return "hello world";
  }

  function des () public {
      address payable addr = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
      selfdestruct(addr);
  
  }


 }