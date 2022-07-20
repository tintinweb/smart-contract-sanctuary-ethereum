/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;
contract Test {
    uint256 private x;
    constructor(uint256 y){
        x=y;  
    }
    function setX(uint256 y) public{
        x=y;
    }
    function getX() public view returns (uint256){
        return x;
    }
}