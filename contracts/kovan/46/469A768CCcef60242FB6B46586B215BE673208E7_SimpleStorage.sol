// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
  uint256 public favNum;

  event storedNumber (
    uint256 indexed oldNum,
    uint256 indexed newNum,
    uint256 addedNum,
    address sender
  );
  
  function store(uint256 _myfavnum) public {
    emit storedNumber(
      favNum,
      _myfavnum,
      favNum + _myfavnum,
      msg.sender
    ); 
    favNum=_myfavnum;
  }

  function retrieve() public view returns(uint256) {
    return favNum;
  }
}