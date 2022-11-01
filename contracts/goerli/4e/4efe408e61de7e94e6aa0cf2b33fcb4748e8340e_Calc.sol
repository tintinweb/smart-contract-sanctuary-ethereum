/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

/*
    @title
    @dev
*/

contract Calc {
    int private result;

    function add(int _a, int _b) public returns (int c) {
        c = result = _a + _b;
    }


    function sub(int _a, int _b) public returns (int) {
        return result = _a - _b;
    }

    function mul(int _a, int _b) public returns (int) {
        return result = _a * _b;
    }

    function div(int _a, int _b) public returns (int) {
        return result = _a / _b;
    }

    function GetResult() public view returns (int) {
        return result;
    }
}