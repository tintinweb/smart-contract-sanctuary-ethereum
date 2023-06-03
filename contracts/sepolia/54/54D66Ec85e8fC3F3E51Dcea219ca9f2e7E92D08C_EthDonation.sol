// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error EthDonation__DonationFailed();

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

    // Function takes the user name, message and ethAmount.
    function donateEth(
        string memory _name,
        string memory _message,
        uint256 _ethAmount
    ) public payable {
        // Making sure eth amount is more than 0
        require(_ethAmount > 0 ether, "Need to send more than 0");

        require(msg.value >= _ethAmount, "Transaction cannot be completed");

        // sending eth
        (bool success, ) = owner.call{value: _ethAmount}("");

        // Checks whether if the transaction went through and then pushes and updates the state of contract.
        if (success) {
            donation.push(
                Donation(msg.sender, _name, _message, block.timestamp)
            );

            totalDonations += 1;
            emit newDonation(msg.sender, block.timestamp, _message, _name);
        }
        // If transfer fails, transaction is reverted and gives error.
        else {
            revert EthDonation__DonationFailed();
        }
    }
}