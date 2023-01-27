// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract DomainRegistry {
    address public owner;
    mapping(address => string[]) public registry;
    string[] registeredDomains;

    constructor() {
        owner = msg.sender;

        registry[owner].push("johnny");
        registeredDomains.push("johnny");

        registry[owner].push("srikar");
        registeredDomains.push("srikar");

        registry[owner].push("ankit");
        registeredDomains.push("ankit");
    }

    function register(string memory domain) public {
        registry[msg.sender].push(domain);
        registeredDomains.push(domain);
    }
}