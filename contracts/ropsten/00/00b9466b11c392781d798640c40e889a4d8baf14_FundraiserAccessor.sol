/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
 
 
contract FundraiserAccessor {
    FundraiserTracker fundraiser;
 
    function setFundraiserAddress(address otherAddress) public {
        fundraiser = FundraiserTracker(otherAddress);
    }
 
    function donate(uint amount) external {
        fundraiser.donate(amount);
    }
 
    function getNumDonations() external view returns (uint) {
        return (fundraiser.getNumDonations());
    } 
 
    function sumDonations() external view returns (uint) {
        return (fundraiser.sumDonations());
    } 
}
 
abstract contract FundraiserTracker {
    function donate(uint newDonation) public virtual;
    function getNumDonations() virtual public view returns (uint);
    function sumDonations() virtual public view returns (uint);
}