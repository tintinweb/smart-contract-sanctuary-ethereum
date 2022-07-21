/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract Counter {
    uint256 public count;
    
    constructor() {
        count=0;
    }
    function countAdd() public{
        count++;
    }
    function countGet() public view returns(uint){
        return count;
    }
}