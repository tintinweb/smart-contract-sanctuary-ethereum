/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Test {
  uint256[] public arr;

  function getArr() external view returns (uint256[] memory) {
    return arr;
  }

  function getArrLength() external view returns (uint256) {
    return arr.length;
  }

  function getBalance(address _address) external view returns (uint256) {
    return address(_address).balance;
  }

  function waste(uint256 _numOfElements) external {
    for (uint256 i; i <= _numOfElements; i++) {
      arr.push(i);
    }
  } 
}