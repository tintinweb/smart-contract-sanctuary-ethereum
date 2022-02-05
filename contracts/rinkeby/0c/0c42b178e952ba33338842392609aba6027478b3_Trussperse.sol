/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Trussperse {
  function massSend(address[] memory _addresses) public payable {
    uint splitAmount = msg.value / _addresses.length;

    for (uint i = 0; i < _addresses.length; i++) {
      bool sent = payable(_addresses[i]).send(splitAmount);
      require(sent, "Failed to send ether!");
    }
  }
}