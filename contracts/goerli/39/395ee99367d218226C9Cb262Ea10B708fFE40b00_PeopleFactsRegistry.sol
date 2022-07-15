/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;
pragma experimental ABIEncoderV2;

contract PeopleFactsRegistry {

  // =========================================================================================================
  //                                                    Models

  // Holds the fact with id of the application that provided the fact
  struct Fact {
    string key;
    string value;
    uint application;
  }

  // Raw facts are used when application information becomes irrelevant, for example, when reading the contract
  struct RawFact {
    string key;
    string value;
  }

  // Person with flag indicating that the person is actually indeed exists (workaround Solidity corks)
  struct Person {
    uint identity;
    bool isPerson;
    Fact[] facts;
  }

  // Properties are result of the aggregated facts. In its simplest implementation, with trivial aggregation
  // the fact will be just an update to the property with the same name
  struct Property {
    string name;
    string value;
  }

  // =========================================================================================================
  //                                                    Persistence

  // hols the count of people in the registry, since the ids are sequential at the moment
  // it also signifies the next Id to be issued
  uint public numberOfPeopleInRegistry;

  // id to Person mapping
  // There are several alternatives of doing this. However, sequential is the only simple way to enable iterating
  // over people, which we need to have to be able to support things like find
  mapping(uint => Person) public people;

  // =========================================================================================================
  //                                                    Construction
  constructor(
  ) {
    numberOfPeopleInRegistry = 0;
  }

  // =========================================================================================================
  //                                                    Events

  event PersonRegistered(uint identity);
  event FactAdded(uint identity, Fact fact);

  // =========================================================================================================
  //                                                    Pure helpers

  // Compares two given strings, true if they are the same
  function compareStrings(string memory a, string memory b) private pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  function aggregate(RawFact[] memory allFacts) private pure returns (Property[] memory) {

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

    Property[] memory ret = new Property[](nextAggregated);

    // copy
    for (uint i = 0; i < nextAggregated; i++) {
      ret[i].name = aggregatedFacts[i].key;
      ret[i].value = aggregatedFacts[i].value;
    }

    return ret;
  }

  // =========================================================================================================
  //                                                    Commands

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

  // =========================================================================================================
  //                                                     Queries

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
        filteredFacts[nextFiltered++] = newRawFact;
      }
    }

    return filteredFacts;
  }

  // creates and returns aggregated view of the person for a given application
  function getAggregatedPersonForApplication(uint identity, uint application) public view returns (Property[] memory) {

    // just a simple check if the given id is ok
    if (!people[identity].isPerson)
      revert("Person is not registered, you can get facts only on known people.");

    // get all the filtered facts
    RawFact[] memory allFacts = getApplicationFacts(identity, application);

    return aggregate(allFacts);
  }

  // creates and returns aggregated application agnostic view of a given person
  function getAggregatedPerson(uint identity) public view returns (Property[] memory) {

    // just a simple check if the given id is ok
    if (!people[identity].isPerson)
      revert("Person is not registered, you can get facts only on known people.");

    Fact[] memory unfilteredFacts = getFacts(identity);

    // get all the unfiltered facts
    RawFact[] memory allFacts = new RawFact[](unfilteredFacts.length);
    for (uint i = 0; i < unfilteredFacts.length; i++) {
      allFacts[i].key = unfilteredFacts[i].key;
      allFacts[i].value = unfilteredFacts[i].value;
    }

    return aggregate(allFacts);
  }

  // Searches registry until it finds the first person matching the template
  // returns its Id if found, reverts if not
  function findAnyByFields(Property[] memory template) public view returns (uint) {

    // iterate over the people
    for (uint i = 0; i < numberOfPeopleInRegistry; i++) {
      Property[] memory allProperties = getAggregatedPerson(i);

      // check if this person matches everything on the template
      bool matches = true;
      for (uint j = 0; j < template.length; j++) {

        bool templateLineFound = false;
        // we need to search for every element in the template, we cannot just go over and match because of
        // the ordering and the fact that absence of property should be handled as a mismatch
        for (uint k = 0; k < allProperties.length; k++) {
          if (compareStrings(template[j].name, allProperties[k].name)) {
            // this is the correct property
            templateLineFound = true;
            if (compareStrings(template[j].value, allProperties[k].value)) {
              // property matches, we do not have to check the rest of properties, we need to move to the next template
              break;
            } else {
              // property was found but did not match
              matches = false;
              break;
            }
          }
        }
        if (!matches) {
          // a property has a wrong value
          break;
        }
        if (templateLineFound) {
          // we went over all the properties and did not find the one with correct name
          matches = false;

          // we do not need to continue with other allProperties
          break;
        }
      }
      if (matches) {
        // this is the one we have been looking for
        return i;
      }
    }

    // we looked at them all, no match
    revert("No match found");
  }
}