// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    uint256 private num = 0;
    
    
    function getcounter() public view returns(uint256){
        return num;
    }
    
    function incrementcounter() public{
        num++;
    }
}