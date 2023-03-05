/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


contract ProgressbarDonation {
    uint public totalDonation;
    uint public donationLimit;
    mapping (address => uint) donator_amount;

    constructor(uint _donationLimit) {
        donationLimit = _donationLimit;
    }

    function donate() public payable{
        require(msg.value > 0, 'Le montant de la donation doit etre superieur a 0');
        donator_amount[msg.sender] += msg.value;
        totalDonation += msg.value;
    }

    function setDonationLimit(uint _donationLimit) public {
        donationLimit = _donationLimit;
    }
}