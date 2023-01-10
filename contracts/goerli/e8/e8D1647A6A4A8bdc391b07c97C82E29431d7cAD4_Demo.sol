// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * The collector card, for ASH
 */
contract Demo {

  function getTime() public view returns(uint) {
    return block.timestamp;
  }
}