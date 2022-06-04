// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract Test{
      function getAandB (uint x) public view returns ( uint a, uint b ) {
          a = x * 2;
          b = x;
          return (a, b);
      }
}