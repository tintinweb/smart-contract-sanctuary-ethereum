// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract RunTheJules {
    address public owner;
    mapping(address => uint256) juices;

    constructor(address _owner) {
        owner = _owner;
    }

    function makeJuice(uint256 num) public {
        juices[msg.sender] = num;
    }
}