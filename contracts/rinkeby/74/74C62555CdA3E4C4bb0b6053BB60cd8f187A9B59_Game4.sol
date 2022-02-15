/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// have someone else deploy this contract
// have them pass in a secret number to the constructor
// then have them give you the deployed contract address

contract Game4 {
  event Winner(address winner);

  bytes32 internal constant SECRET_SLOT = keccak256("secret.variable.slot");

  constructor(uint secret) {
    bytes32 slot = SECRET_SLOT;
    assembly {
      sstore(slot, secret)
    }
  }

  function win(uint guess) payable public {
    uint secret;
    bytes32 slot = SECRET_SLOT;
    assembly {
      secret := sload(slot)
    }
    require(guess == secret, "Incorrect guess!");
    emit Winner(msg.sender);
  }
}