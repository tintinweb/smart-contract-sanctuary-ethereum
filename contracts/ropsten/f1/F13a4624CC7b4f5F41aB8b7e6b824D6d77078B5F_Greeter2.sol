//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter2 {
    uint256 public var1;
    uint256 public var2;
    uint256 public sum;

    function set_test(uint256 _var1, uint256 _var2) public {
        var1 = _var1;
        var2 = _var2;
    }

    function sum_test() public {
        sum = var1 + var2;
    }

    function test() public {
        sum_test();
    }
}