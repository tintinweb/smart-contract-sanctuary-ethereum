// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract DomainRegistry {
    address public owner;
    mapping(string => address) public domainToOwner;

    error DomainTaken(string domain);

    event RegisteredDomain(string domain);

    constructor() {
        owner = msg.sender;
        register("johnny");
        register("kevin");
    }

    function register(string memory domain) public {
        if (domainToOwner[domain] != address(0)) {
            revert DomainTaken(domain);
        }

        domainToOwner[domain] = msg.sender;

        emit RegisteredDomain(domain);
    }
}