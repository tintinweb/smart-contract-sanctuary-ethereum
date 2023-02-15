// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract EarthquakeDonation {

    address public owner;

    Donation [] public donations; 

    struct Donation {
        string demand;
        string latestStatus;
        bool isProvided;
    }

    constructor() {
        owner = msg.sender;
    }

    function addDonationRequest(string memory _demand) external onlyOwner {
        Donation memory newDonation = Donation(_demand, "", false);
        donations.push(newDonation);
    }

    function updateDonationRequest(uint id, string memory _demand, string memory _latestStatus) external onlyOwner {
        donations[id].demand = _demand;
        donations[id].latestStatus = _latestStatus;
    }

    function makeDonation(uint id) external onlyOwner {
        donations[id].isProvided = true;
    }
    
    function deleteDonationRequest(uint id) external onlyOwner {
        donations[id].latestStatus="deleted";
    }

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not allowed to call the function");
        _;
    }
}