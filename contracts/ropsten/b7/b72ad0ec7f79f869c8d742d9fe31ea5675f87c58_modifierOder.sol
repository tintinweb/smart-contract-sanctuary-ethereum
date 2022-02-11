/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract modifierOder {
    address owner;
    uint256 a;
    
    constructor() {
        owner = msg.sender;
    }
    
    function test(uint num) public checkPara(num) returns(uint256) {
        a = 10;
        return a;
    }
    
    // 修改a 
    modifier checkPara(uint number) {
        a = 1;
        _;
        a = 100;
    }

}