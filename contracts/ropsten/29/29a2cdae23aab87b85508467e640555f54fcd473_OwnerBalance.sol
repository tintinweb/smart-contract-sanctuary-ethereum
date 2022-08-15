// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9;

contract OwnerBalance {
  address private _owner;

  event OwnerAccess();

  constructor() {
    _owner = msg.sender;
  }

  function owner() public view returns (address) {
    return _owner;
  }

  function onlyOwner() public {
    require(_owner == msg.sender, "Not an owner!");
    emit OwnerAccess();
  }

}