/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: UNLICENSED
contract Array {
  string[] private fruits = ["banana", "apple", "avocado", "pineapple", "grapes"];

  function push(string memory item) public {
    fruits.push(item);
  }

  function get(uint256 index) public view returns (string memory) {
    return fruits[index];
  }

  function remove(uint256 index) public returns (bool) {
    if (index >= 0 && index < fruits.length) {
      fruits[index] = fruits[fruits.length - 1];
      fruits.pop();
      return true;
    }
    revert("index out of bounds");
  }

  function getAll() public view returns (string[] memory) {
    return fruits;
  }
}