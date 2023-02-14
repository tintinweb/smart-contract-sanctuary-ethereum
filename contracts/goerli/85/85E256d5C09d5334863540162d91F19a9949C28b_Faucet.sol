/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Faucet {
  
  function withdraw(uint _amount) public {
    // users can only withdraw .1 ETH at a time, feel free to change this!
    require(_amount <= 100000000000000000);
    payable(msg.sender).transfer(_amount);
  }

  // fallback function
  receive() external payable {}
}