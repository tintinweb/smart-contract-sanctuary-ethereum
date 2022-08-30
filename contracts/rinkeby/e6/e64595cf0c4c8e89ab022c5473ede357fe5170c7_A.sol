pragma solidity ^0.8.0;

import "contracts/clibrary.sol";

contract A {
uint256 public number;
  function setNumber(uint256 _number) public {
 number = C.add(_number * 105,50); 
}
  function a() public pure returns (uint256) {
        uint256 x = 50;
        return C.add(50, x);
    }

    function b() public pure returns (uint256) {
      uint256 y = 100;
      return C.add(100, y);
    }

    function c() public pure returns (uint256) {
      return 999;
    }
}

pragma solidity ^0.8.0;

library C {
  function add(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library D {
  function sub(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a - b;
    assert(c <= a);
    return c;
  }
}