// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract DomainRegistry {
    address public owner;
    mapping(address => string[]) public registry;
    mapping(string => bool) public registeredDomains;

    constructor() {
        owner = msg.sender;
        register("johnny");
        register("kevin");
    }

    function register(string memory domain) public {
        registry[msg.sender].push(domain);
        registeredDomains[domain] = true;
    }
}