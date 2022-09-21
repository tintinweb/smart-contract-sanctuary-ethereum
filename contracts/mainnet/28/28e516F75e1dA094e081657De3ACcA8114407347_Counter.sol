/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Counter {
  error AlwaysRevert();

  uint256 public count = 0;

  function increment() public returns (uint256) {
    count += 10;
    return count;
  }

  function reset() public {
    count = 0;
  }

  function alwaysRevert() public pure {
    revert AlwaysRevert();
  }

  function alwaysRevertWithString() public pure {
    revert("always revert");
  }
}