// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract RunTheJules {
    mapping(address => uint256) juices;

    function makePickleJuice(uint256 num) public {
        juices[msg.sender] = num;
    }
}