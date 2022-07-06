// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Sum {
  uint256 number;

  function store(uint256 num) public {
      number = num - num % 3;
  }

  function retrieve() public view returns (uint256){
      return number;
  }
}