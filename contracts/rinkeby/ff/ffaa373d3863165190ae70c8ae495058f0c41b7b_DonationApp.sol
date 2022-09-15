/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity 0.8.17;

contract DonationApp {
    // Tracking total donations.
    uint256 totalDonations;

    // Setting up owner address.
    address payable public owner;

    //creating a new event
    event newDonation(
        address indexed from,
        uint256 timestamp,
        string message,
        string name
    );

    constructor() payable {
        owner = payable(msg.sender);
    }

    // Creating a new struct
    struct Donation {
        address from; // Address of the person who is donating
        string name; // Name of the donator
        string message; // Message left by the donator
        uint256 timestamp; // Time when donation happened
    }

    // Variable donation holds array of struct(Donators)
    Donation[] donation;

    // Function returns the struct Array(donation) to us
    function getAllDonations() public view returns (Donation[] memory) {
        return donation;
    }

    // Function returns total number of donations made
    function getTotalDonations() public view returns (uint256) {
        return totalDonations;
    }

    // Creates a function that takes paras and lets users donate

    function doDonation(
        string memory _name,
        string memory _message,
        uint256 _ethAmount
    ) public payable {
        uint256 amount = 0.002 ether;
        require(_ethAmount <= amount, "Not enough ETH");

        totalDonations += 1;

        // pushing the para's into the array
        donation.push(Donation(msg.sender, _name, _message, block.timestamp));

        // sending eth
        (bool success, ) = owner.call{value: _ethAmount}("");
        require(success, "Donation Failed");

        emit newDonation(msg.sender, block.timestamp, _message, _name);
    }
}