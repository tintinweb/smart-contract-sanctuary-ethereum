/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity >=0.4.22 <0.9.0;

contract Simple{
  uint public storedData;

  function set(uint x) public {
    storedData = x;
  }

  function get() view public returns (uint retVal) {
    return storedData;
  }
}