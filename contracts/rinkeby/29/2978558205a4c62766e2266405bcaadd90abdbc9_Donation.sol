/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Donation {
  uint totalDonations; // the amount of donations
  address payable owner; // contract creator's address

  //contract settings
  constructor() {
    owner = payable(msg.sender); // setting the contract creator
  }

  // public function to return the amount of donations
  function getTotalDonations() view public returns(uint) {
    return totalDonations;
  }

  //public function to make donate
  function donate() public payable {
    (bool success,) = owner.call{value: msg.value}("");
    require(success, "Failed to send money");
  }
}