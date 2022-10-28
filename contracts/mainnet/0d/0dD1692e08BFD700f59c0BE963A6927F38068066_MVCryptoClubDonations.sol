/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MVCryptoClubDonations {
  address payable public  owner;

    
  struct Donation {
    uint amount;
    address addr;
    string name;
  }

  Donation[] public donations;

  constructor() {
    owner = payable(msg.sender);
  } 

  function getDonations() public view returns (Donation[] memory) {
    return donations;
  }

  function donate(string memory name) public payable {  
    donations.push(Donation(msg.value, msg.sender, name));
    payable(owner).transfer(msg.value);
  } 
}