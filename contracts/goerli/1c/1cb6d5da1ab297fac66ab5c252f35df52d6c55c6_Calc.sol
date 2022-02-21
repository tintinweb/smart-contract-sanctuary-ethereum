/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Calc {
    int private result; // 外部不可访问

    function add(int a, int b) public returns (int c) { // 类似于go的返回值声明，外部可以访问
        result = a + b;
        c = result;
    }

    function min(int a, int b) public returns (int) { // 不声明返回值，自行返回
        result = a - b;
        return result;
    }
    
    function mul(int a, int b) public returns (int) {
        result = a * b;
        return result;
    }

    function div(int a, int b) public returns (int) {
        result = a / b;
        return result;
    }

    function getResult() public view returns(int) { // view修饰表示只读
        return result;
    }
}