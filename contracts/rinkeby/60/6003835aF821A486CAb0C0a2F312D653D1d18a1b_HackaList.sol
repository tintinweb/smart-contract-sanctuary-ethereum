/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract HackaList {

  // Number of addresses hackalisted
  uint8 public numAddressesHackaListed;
  
  // Max number of hacker addressess allowed to participate in the hackathon
  uint8 public maxHackaListed;

  // Map hackalisted addresses to boolean
  mapping(address => bool) public hackaListedAddresses;

  // Set the max number of hacker addresses on constructor
  constructor(uint8 _maxHackaListed) {
    maxHackaListed = _maxHackaListed;
  }

  /**
  * addToHackaList - Add an address to the HackaList
  */
  function addToHackaList() public {
    // Check if hacker is already in
    require(!hackaListedAddresses[msg.sender], "You're a luck one! Already in the HackaList!");
    // Check if maxHackaListed is not reached
    require(numAddressesHackaListed < maxHackaListed, "Sorry, the Whitelist is full");
    // Add the address which called the function to the hackaListedAddresses
    hackaListedAddresses[msg.sender] = true;
    // Increase the number of hackalisted addresses
    numAddressesHackaListed += 1;
  }
}