/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity ^0.8.7;
contract C {
  uint256 a;
  constructor(uint256 _a) {
    a = _a; 
  }
  function setA(uint256 _a) public payable {
    a = _a;
  }
  function getA() internal view returns(uint256)  {
    return a;
  }
  fallback() external {
    getA();
  }
}