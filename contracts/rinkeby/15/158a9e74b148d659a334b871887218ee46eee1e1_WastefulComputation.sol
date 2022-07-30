/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract WastefulComputation {
  uint256[] public array;

  function waste(uint256 arrLength) external {
    uint256[] memory arr = new uint256[](arrLength);

    for (uint256 i = 0; i < arrLength; i++) {
      arr[i] = i;
    }

    array = arr;
  }

  function ultraWaste(uint256 arrLength) external {
    uint256[] memory arr = new uint256[](arrLength);

    for (uint256 i = 0; i < arrLength; i++) {
      arr[i] = i + block.timestamp + block.difficulty - 4128365;
    }

    array = arr;
  }

  function hyperWaste() external {
    uint256[] memory arr = new uint256[](1e6);

    for (uint256 i = 0; i < 1e6; i++) {
      arr[i] = i;
    }

    array = arr;
  }

  function giganticWaste() external {
    uint256[] memory arr = new uint256[](1e12);

    for (uint256 i = 0; i < 1e12; i++) {
      arr[i] = i;
    }

    array = arr;
  }

  function monumentalWaste() external {
    uint256[] memory arr = new uint256[](1e18);

    for (uint256 i = 0; i < 1e18; i++) {
      arr[i] = i;
    }

    array = arr;
  }
}