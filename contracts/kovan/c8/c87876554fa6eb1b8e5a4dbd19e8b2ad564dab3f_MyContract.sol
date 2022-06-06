/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

pragma solidity ^0.8.0;

contract MyContract {
  uint value;

  function get() public view returns (uint) {
    return value;
  }
  function double(uint x) public {
    value = x * 2;
  }
}