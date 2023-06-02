/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


contract Multitransfer {

  function transfer(uint256[] memory amounts, address payable[] memory receivers) public payable {
      require(amounts.length == receivers.length, "two array should has same size");
      uint256 total;
      for(uint i=0;i<amounts.length;i++) {
        total += amounts[i];
      }
      require(total == msg.value, "invalid amounts");
      for(uint i=0; i<amounts.length;i++) {
        receivers[i].transfer(amounts[i]);
      }
  }

}