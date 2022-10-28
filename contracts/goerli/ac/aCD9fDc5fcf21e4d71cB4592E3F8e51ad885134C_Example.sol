/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library SafeMath { 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
}

contract Example {
    using SafeMath for uint;
    function doAdd(uint _a, uint _b) public  pure returns (uint) {
        return _a.add(_b);
    }
    function doSub(uint _a, uint _b) public  pure returns (uint) {
        return _a.sub(_b);
    }
}