/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

pragma solidity ^0.8.0;

contract TTT {
  uint public a;

  constructor() {}

  function getA() external view returns (uint) {
    return a;
  }
}