/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract DonationContract {
    address public latestDonor;
    uint public latestDonation;
    uint public totalDonation;

    function donate(uint amount) public {
        require(amount > 0, "Donation amount must be greater than zero");
        latestDonor = msg.sender;
        latestDonation = amount;
        totalDonation += amount;
    }

    function getLatestDonation() public view returns (address, uint) {
        return (latestDonor, latestDonation);
    }

    function getTotalDonation() public view returns (uint) {
        return totalDonation;
    }
}