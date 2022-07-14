/**
 *Submitted for verification at Etherscan.io on 2022-07-13
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
        uint application;
    }

    struct RawFact {
        string key;
        string value;
    }

    struct Person {
        uint identity;
        bool isPerson;

        // string facts;
        Fact[] facts;
    }

    // this is a helper for aggregating facts
    struct MappedFact {
        string factValue;
        bool isFactValue;
    }

    constructor(
    ) {
        numberOfPeopleInRegistry = 0;
    }

    // Events

    event PersonRegistered(uint identity);
    event FactAdded(uint identity, Fact fact);

    // Commands

    // adds provided identity to the registry
    function registerPerson() public {
        uint issuedIdentity = numberOfPeopleInRegistry++;
        people[issuedIdentity].identity = issuedIdentity;
        people[issuedIdentity].isPerson = true;
        emit PersonRegistered(issuedIdentity);
    }

    // appends facts to a known identity
    function addFact(uint identity, uint application, string memory factKey, string memory factValue) public {
        if (!people[identity].isPerson)
            revert("Person is not registered, you need to register it to add facts.");

        Fact memory newFact;
        newFact.key = factKey;
        newFact.value = factValue;
        newFact.application = application;
        people[identity].facts.push(newFact);

        emit FactAdded(identity, newFact);
    }

    // Queries

    // returns the current set of facts accumulated for a given identity
    function getFacts(uint identity) public view returns (Fact[] memory) {
        if (!people[identity].isPerson)
            revert("Person is not registered, you can get facts only on known people.");
        return people[identity].facts;
    }

    // returns facts only for given application
    function getApplicationFacts(uint identity, uint application) public view returns (RawFact[] memory) {
        if (!people[identity].isPerson)
            revert("Person is not registered, you can get facts only on known people.");

        // it is really strange how mem allocations work, looks like we have to explicitly allocate the return array
        // need to know the size for the return array
        uint filteredSize;
        for (uint i = 0; i < people[identity].facts.length; i++) {
            if (people[identity].facts[i].application == application)
                filteredSize++;
        }

        RawFact[] memory filteredFacts = new RawFact[](filteredSize);
        uint nextFiltered = 0;

        // go over all the facts and filter out only the facts for given app
        for (uint i = 0; i < people[identity].facts.length; i++) {
            if (people[identity].facts[i].application == application) {
                RawFact memory newRawFact;
                newRawFact.key = people[identity].facts[i].key;
                newRawFact.value = people[identity].facts[i].value;
                filteredFacts[nextFiltered++]=newRawFact;
            }
        }

        return filteredFacts;
    }

    // Compares two given strings, true if they are the same
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function getAggregatedPerson(uint identity, uint application) public view returns (RawFact[] memory) {

        // just a simple check if the given id is ok
        if (!people[identity].isPerson)
            revert("Person is not registered, you can get facts only on known people.");

        // get all the filtered facts
        RawFact[] memory allFacts = getApplicationFacts(identity, application);

        // Sure, this would be easier if we could just use a map of some sort, but since
        // "Mappings cannot be created dynamically, you have to assign them from a state variable."
        // we need to improvise a bit here
        // The plan is to pre-allocate an array of the same size (not the best, what there isnt anything resizable
        // that is available to us here) and do the simple n^2 for aggregation
        // since we do not really want to have empty entries in the responses, we will re-allocate and copy
        // into a perfectly sized array

        RawFact[] memory aggregatedFacts = new RawFact[](allFacts.length);

        uint nextAggregated = 0;

        // aggregation loop
        for (uint i = 0; i < allFacts.length; i++) {
            bool foundInAggregatedArray = false;
            for (uint j = 0; j < nextAggregated; j++) {
                if (compareStrings(allFacts[i].key, aggregatedFacts[j].key)) {
                    // this is just an update in-place, not adjusting the nextAggregated
                    aggregatedFacts[j].value = allFacts[i].value;
                    foundInAggregatedArray = true;
                    break;
                }
            }
            if (!foundInAggregatedArray) {
                // this fact is not in the aggregate yet, add it and adjust nextAggregated
                aggregatedFacts[nextAggregated].key = allFacts[i].key;
                aggregatedFacts[nextAggregated].value = allFacts[i].value;
                nextAggregated++;
            }
        }

        RawFact[] memory ret = new RawFact[](nextAggregated);

        // copy
        for (uint i = 0; i < nextAggregated; i++) {
            ret[i].key = aggregatedFacts[i].key;
            ret[i].value = aggregatedFacts[i].value;
        }

        return ret;
    }
}