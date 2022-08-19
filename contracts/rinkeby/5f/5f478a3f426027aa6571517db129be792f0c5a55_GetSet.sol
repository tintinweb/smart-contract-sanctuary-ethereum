/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GetSet {
  uint256 public total;
  mapping(address => uint256) private numbers;
  mapping(uint256 => uint256) private heavyArr;

  function getTotal() external view returns (uint256) {
    return total;
  }

  function setNumber(uint256 _num) external returns (bool) {
    total = total - numbers[msg.sender] + _num;
    numbers[msg.sender] = _num;
    return true;
  }

  function setHeavy() external returns (bool) {
    for(uint i = 0; i < 100; i++) {
      heavyArr[i] = heavyArr[i] + 1;
    }
    return true;
  }

  function getNumber(address _user) external view returns (uint256) {
    return numbers[_user];
  }
}