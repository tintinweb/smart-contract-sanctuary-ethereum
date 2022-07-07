/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;

// Defines a contract named `HelloWorld`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract PeopleRegistry {
    uint public numberOfPeopleInRegistry;
    mapping(uint => person) public people;
    struct person {
        uint identity;
        bool isPerson;

        string facts;
    }
    constructor(
    ) {
        numberOfPeopleInRegistry = 0;
    }

    // Events

    event PersonRegistered(uint identity);

    // Commands

    // adds provided identity to the registry
    function registerPerson(string memory facts) public {
        uint issuedIdentity = numberOfPeopleInRegistry++;
        people[issuedIdentity].facts = facts;
        people[issuedIdentity].identity = issuedIdentity;
        people[issuedIdentity].isPerson = true;
        emit PersonRegistered(issuedIdentity);
    }

    // appends facts to a known identity
    function addFact(uint identity, string memory newFacts) public {
        if (!people[identity].isPerson)
            revert("Person is not registered, you need to register it to add facts.");

        // let this override for now
        people[identity].facts = newFacts;
    }

    // returns the current set of facts accumulated for a given identity
    function getFacts(uint identity ) public view returns (string memory) {
        if (!people[identity].isPerson)
            revert("Person is not registered, you can get facts only on known people.");
        return people[identity].facts;
    }
}