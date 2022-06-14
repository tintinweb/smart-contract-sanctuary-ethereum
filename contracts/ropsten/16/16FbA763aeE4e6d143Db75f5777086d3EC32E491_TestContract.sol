// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test2Contract} from './Test2Contract.sol';

contract TestContract {
    uint256 public A;
    function test() public{
      uint256 a = 10;
      A = Test2Contract.test2(a);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Test2Contract {

    function test2(uint256 a) external pure returns (uint256)  {
        return a + 2; 
    }
}