/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Lab1 {
    mapping(address => uint) private values;
    event Log();

    function write(uint val) public {
        values[msg.sender] = val;
        emit Log();
    }

    function read() public view returns (uint){
        return values[msg.sender];
    }
}