/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

contract Calc {
    int256 private result;

    function add(int256 a, int256 b) public returns (int256 c) {
        result = a+b;
        c = result;
    }
    function min(int a, int b ) public returns (int) {
        result = a -b;
        return result;
    }
    function mul(int a, int b) public returns (int){
        result = a * b;
        return result;
    }
    function div(int a, int b) public returns (int) {
        result = a/b;
        return result;
    }
    function getResult() public view returns(int) {
        return result;
    }
}