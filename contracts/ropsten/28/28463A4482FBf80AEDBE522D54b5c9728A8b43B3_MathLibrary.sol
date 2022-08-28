/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

library MathLibrary {
     function multiply(uint a, uint b) public view returns (uint, address) {
          return (a * b, address(this));
      }
}