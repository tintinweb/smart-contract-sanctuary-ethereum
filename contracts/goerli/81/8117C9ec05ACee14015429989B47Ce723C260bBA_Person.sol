/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;

// Defines a contract named `HelloWorld`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract Person {

    string public firstName;
    string public lastName;

    // this really should be a date, just do not want to deal with conversions for now
    string public dob;

    string public identityType;
    string public identity;

    string public facts;

    // Emitted to notify about new fact about the person
    event FactAdded(string oldFacts, string newFact);

    constructor(
        string memory initFirstName,
        string memory initLastName,
        string memory initDob,
        string memory initIdentityType,
        string memory initIdentity
    ) {
        firstName = initFirstName;
        lastName = initLastName;
        dob = initDob;
        identityType = initIdentityType;
        identity = initIdentity;
        facts = "Root|";
    }

    // A public function that accepts a string argument and updates the `message` storage variable.
    function addFact(string memory newFact) public {
        string memory oldFacts = facts;

        // no string concatenation... hmm, ok for now
        // facts += newFact + "|";
        facts = newFact;

        emit FactAdded(oldFacts, newFact);
    }
}