/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Donation_Contract{

string _seniors;
string _donor;
string _title_donation;
string _description;
uint _donate;
uint _balance;
uint _goal;

constructor(string memory title_donation, string memory description, string memory seniors, uint balance, uint goal){
    // require(balance>0, "Donate greater zero");
    _title_donation = title_donation;
    _description = description;
    _seniors = seniors;
    _balance = balance;
    _goal = goal;
}

function getBalance() public view returns(uint balance){
    return _balance;
}

function donate(string memory name_donor, uint amount) public{
    _donor = name_donor;
    _balance += amount;
}
}