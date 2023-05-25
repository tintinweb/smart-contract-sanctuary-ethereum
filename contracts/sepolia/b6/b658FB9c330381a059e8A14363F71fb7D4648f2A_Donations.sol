/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Donations {
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  // Function to donate
  function donate() public payable {
    require(msg.value > 0, "Donation needs to be a positive value");
  }

  // Withdraw ether
  function withdraw() public payable {
    require(msg.sender == owner, "Only the owner can withdraw!");

    uint balance = address(this).balance;
    require(balance > 0, "No ether left to withdraw");

    (bool success, ) = (msg.sender).call{value: balance}("");
    require(success, "Transfer failed.");
  }
}