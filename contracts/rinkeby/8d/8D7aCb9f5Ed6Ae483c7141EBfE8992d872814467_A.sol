/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract A {
    address public a;

    constructor() {}

    function test() public returns (address b){
        b = address(this);
        a = b;
    }

    function test2(address _a) public {
        a = _a;
    }
}