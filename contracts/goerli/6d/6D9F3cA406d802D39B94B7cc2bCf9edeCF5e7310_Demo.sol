// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Demo {

    function getTime() public view returns (uint) {
      return block.timestamp;
    }
}