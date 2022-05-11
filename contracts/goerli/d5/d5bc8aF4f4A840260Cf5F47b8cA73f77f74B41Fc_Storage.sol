/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
contract Storage {
    mapping(address => string) public data;

    function store(string calldata value) public {
        data[msg.sender] = value;
    }

    function retrieve(address user) public view returns (string memory){
        return data[user];
    }
}