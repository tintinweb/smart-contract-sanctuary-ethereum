/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Calc {
    int private result;

    function add(int a, int b) public {
        result = a+b;
    }
    function show() public view returns (int){
        return result;
    }
}