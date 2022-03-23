/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
 
contract FundraiserTracker {
    uint[] donations = new uint[](100);
    uint numDonations = 0;
 
    function donate(uint newDonation) public {
        donations[numDonations] = newDonation;
        numDonations++;
    }
 
    function getNumDonations() public view returns (uint) {
        return (numDonations);
    }
 
    function sumDonations() public view returns (uint) {
        uint sum = 0;
 
        for (uint i = 0; i < numDonations; i++) {
            sum += donations[i];
        }
 
        return (sum);
    }
}