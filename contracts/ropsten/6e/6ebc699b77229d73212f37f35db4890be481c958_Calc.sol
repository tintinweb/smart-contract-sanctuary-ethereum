/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Calc {
    int public result;

    constructor() {
        result = 10;
    }

    receive() external payable {
        
    }

    function add(int a, int b) external returns(int c) {
        result = a + b;
        c = result;
    }

    function sub(int a, int b) internal returns(int) {
        result = a - b; 
        return result;
    }

    function test1(int a, int b)public returns(int) {
        return this.add(a, b);
    }
}