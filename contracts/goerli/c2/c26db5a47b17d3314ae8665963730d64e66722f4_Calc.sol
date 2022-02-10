/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Calc {
    int private result;

    function add(int a, int b) public returns (int c) {
        result = a + b;
        c = result;
    }

    // 注意: return variable 可以不宣告!
    function min(int a, int b) public returns (int) {
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

    function getResult() public view returns (int) {
        return result;
    }
}