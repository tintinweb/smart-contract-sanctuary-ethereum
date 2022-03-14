/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.6.4;
// We have to specify what version of compiler this code will compile with

contract SimpleArithmetics2 {
  function Add(int x, int y) pure public returns (int) {
    return x + y;
  }

  function Sub(int x, int y) pure public returns (int) {
    return x - y;
  }

  function Mul(int x, int y) pure public returns (int) {
    return x * y;
  }

  function Div(int x, int y) pure public returns (int) {
    return x / y;
  }
}