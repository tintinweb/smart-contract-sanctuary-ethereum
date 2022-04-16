// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface C2 {
    function set_test(uint256 _var1, uint256 _var2) external;
    function sum_test() external;
    function test() external;
}

contract CallTest {
    address constant private addr = 0xF13a4624CC7b4f5F41aB8b7e6b824D6d77078B5F;
    C2 private c2;

    constructor() {
        c2 = C2(addr);
    }

    function mytest() public {
        c2.set_test(1, 2);
    }
}