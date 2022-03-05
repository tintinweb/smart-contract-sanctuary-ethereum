/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


contract Forwarder {
  address payable public destinationAddress;


 constructor() {
   destinationAddress = payable(msg.sender);
 }
  
 
  fallback()  payable external {
    destinationAddress.transfer(msg.value);
  }
}