/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;
pragma experimental ABIEncoderV2;

contract PeopleFactsRegistry {
    uint public numberOfPeopleInRegistry;
    mapping(uint => Person) public people;

    struct Fact {
        string key;
        string value;
    }

    struct Person {
        uint identity;
        bool isPerson;

        // string facts;
        Fact[] facts;
    }
    constructor(
    ) {
        numberOfPeopleInRegistry = 0;
    }

    // Events

    event PersonRegistered(uint identity);

    // Commands

    // adds provided identity to the registry
    function registerPerson() public {
        uint issuedIdentity = numberOfPeopleInRegistry++;
        people[issuedIdentity].identity = issuedIdentity;
        people[issuedIdentity].isPerson = true;
        emit PersonRegistered(issuedIdentity);
    }

    // appends facts to a known identity
    function addFact(uint identity, string memory factKey, string memory factValue) public {
        if (!people[identity].isPerson)
            revert("Person is not registered, you need to register it to add facts.");

        Fact memory newFact;
        newFact.key = factKey;
        newFact.value = factValue;
        people[identity].facts.push(newFact);
    }

    // Queries

    // returns the current set of facts accumulated for a given identity
    function getFacts(uint identity ) public view returns (Fact[] memory) {
        if (!people[identity].isPerson)
            revert("Person is not registered, you can get facts only on known people.");
        return people[identity].facts;
    }
}