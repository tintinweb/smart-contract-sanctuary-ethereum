/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract EthDonation {
    // Tracking total number of donations.
    uint256 totalDonations;

    // Setting up owner address.
    address payable public owner;

    // Creates new event to keep track of all the donations happening.
    event newDonation(
        address indexed from,
        uint256 timestamp,
        string message,
        string name
    );

    constructor() payable {
        // Sets up
        owner = payable(msg.sender);
    }

    // Creating a new data type to hold data of Donations.
    struct Donation {
        address from; // Address of the person who is donating.
        string name; // Name of the donator.
        string message; // Message left by the donator.
        uint256 timestamp; // Block timestamp when the donations occurs.
    }

    // Variable donation holds array of struct(Donation).
    Donation[] donation;

    /*
     * Function returns the Array(donation) to us.
     * This will make it easy to retrieve the coffee from frontend.
     */
    function getAllDonations() public view returns (Donation[] memory) {
        return donation;
    }

    // Returns total number of donations made.
    function getTotalDonations() public view returns (uint256) {
        return totalDonations;
    }

    // Returns owner address
    function getOwnerAddress() public view returns (address) {
        return owner;
    }

    // Function takes the user name, message and ethAmount.
    function donateEth(
        string memory _name,
        string memory _message,
        uint256 _ethAmount
    ) public payable {
        // Require reverts the transaction if the donation amount is 0.
        require(_ethAmount > 0, "Amount must be greater than 0");

        totalDonations += 1;

        // pushing the info into the array.
        donation.push(Donation(msg.sender, _name, _message, block.timestamp));

        // sending eth
        (bool success, ) = owner.call{value: _ethAmount}("");
        require(success, "Donation Failed");

        emit newDonation(msg.sender, block.timestamp, _message, _name);
    }
}