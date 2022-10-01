/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
contract MyContract {
  function sum(uint256 a, uint256 b) external pure returns(uint256 c) {
    c = a + b;
  }
}