/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract Homework01 {

    mapping(address => uint256) numbers;
    
    function store(uint256 value) public {
        numbers[msg.sender] = value;
    }

    function retrieve(address addr) public view returns(uint256) {
        return numbers[addr];
    }

}