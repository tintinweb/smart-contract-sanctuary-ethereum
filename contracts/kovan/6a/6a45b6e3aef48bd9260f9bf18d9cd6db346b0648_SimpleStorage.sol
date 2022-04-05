/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity ^0.8.6;

contract SimpleStorage {
  uint public data;
  uint256 public data1;

  function setData(uint _data) external {
    data = _data;
  }
  function setD(uint256 _data) public {
    data1 = _data;
  }
}