/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;


contract Storage {

    mapping(address => uint256) numbers;

    function store(uint256 num) public {
        numbers[msg.sender] = num;
    }

    function retrieve(address owner) public view returns (uint256){
        return numbers[owner];
    }
}