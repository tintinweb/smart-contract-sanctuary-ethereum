/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

pragma solidity ^0.7.0;

library C {
  function add(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract A {
    function a() public pure returns (uint256) {
        uint256 x = 50;
        return C.add(50, x);
    }

    function b() public pure returns (uint256) {
      uint256 y = 100;
      return C.add(100, y);
    }
}