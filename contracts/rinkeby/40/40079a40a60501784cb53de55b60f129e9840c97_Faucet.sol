/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Faucet {

  function withdraw(uint _amount) public {
    // users can only withdraw .05 ETH at a time, feel free to change this!
    require(_amount <= 50000000000000000);
    payable(msg.sender).transfer(_amount);
  }

  // fallback function
  receive() external payable {}
}