/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-04
*/

// File: contracts\SimpleStorage.sol

pragma solidity ^0.8.6;

contract SimpleStorage {
  uint public data;
  uint256 public data2;

  function setData(uint _data) external {
    data = _data;
  }
  function setD(uint256 _data) public {
    data2 = _data;
  }
}