/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MSMV1 {
  string public name;

  // fallback() external payable {
     
    
  // }

   function setXandSendEther(string memory _x) public returns (string memory) {
        name = _x;
       return name;
   }
}