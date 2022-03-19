/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

pragma solidity ^0.8.10;

contract SimpleStorage {
  uint myVariable;

  function set(uint x) public {
    myVariable = x;
  }

  function get()  public view returns (uint) {
    return myVariable;
  }
}