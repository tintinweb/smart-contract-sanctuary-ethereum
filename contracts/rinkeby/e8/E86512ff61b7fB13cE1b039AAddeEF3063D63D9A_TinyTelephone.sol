/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract TinyTelephone {
  // 10000000000000000 = 0.01 eth
  function attack() external payable {
    payable(0x6E8BBE0Ea179E069B3fBD7FFa16a93d1F6aE2Ef5).call{value: msg.value}("");
  }

  receive() external payable {
    revert();
  }

  function viewAddress() external view returns(address) {
    return address(this);
  }
}