// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract RunTheJules {
    address public the_owner;
    mapping(address => address) juices;

    constructor(address _owner) {
        the_owner = _owner;
    }

    function makeJuice(address _address) public {
        juices[msg.sender] = _address;
    }
}