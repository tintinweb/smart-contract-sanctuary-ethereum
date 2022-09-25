//SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

contract Dexter {
  function balanceOf(address) external pure returns (uint256) {
    return 100;
  }

  function transferFrom(
    address,
    address,
    uint256
  ) external pure returns (bool) {
    return true;
  }
}