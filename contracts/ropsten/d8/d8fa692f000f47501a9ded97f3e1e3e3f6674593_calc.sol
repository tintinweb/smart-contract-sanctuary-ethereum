/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract calc {
    int private result;
    function add(int x,int y) public returns(int) {
        result = x + y;
        return result;
    }
    function min(int x,int y) public returns(int) {
        result = x - y;
        return result;
    }    
    function mul(int x,int y) public returns(int) {
        result = x * y;
        return result;
    }    
    function div(int x,int y) public returns(int) {
        result = x / y;
        return result;
    }    
    function getResult() public view returns(int) {
        return result;
    }

}