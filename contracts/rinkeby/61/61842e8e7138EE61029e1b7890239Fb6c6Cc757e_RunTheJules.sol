// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract RunTheJules {
    address public the_owner;
    mapping(address => address) juices;
    string uri;

    constructor(address _owner) {
        the_owner = _owner;
    }

    function makeJuice(string memory _uri) public {
        uri = _uri;
    }
}