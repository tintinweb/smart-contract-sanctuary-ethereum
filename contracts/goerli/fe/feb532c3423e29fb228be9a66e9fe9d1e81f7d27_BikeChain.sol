/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BikeChain {

    address owner;

    constructor() {
        owner = msg.sender;
    }
    // Add yourself as a renter

    struct Renter {
        address payable walletAddress;
        string firstName;
        string lastName;
        bool canRent; 
        bool active;
        uint balance;
        uint due;
        uint start;
        uint end;
    }

    mapping(address => Renter) public renters;

    function addRenter( address payable walletAddress, string memory firstName, string memory lastName, bool canRent,  bool active, uint balance, uint due, uint start, uint end) public{
        // Sample data: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, "Nicogs", "World", true, false, 0, 0, 0, 0
        renters[walletAddress] = Renter(walletAddress, firstName, lastName, canRent, active, balance, due, start, end);
    
    }
    // Checkout Bike
    function checkOut(address walletAddress) public {
        require(renters[walletAddress].due == 0, "You have a pending balance to be payed!");
        require(renters[walletAddress].canRent == true, "You cannot rent at this time.");

        renters[walletAddress].active = true;
        renters[walletAddress].canRent = false;
        renters[walletAddress].start = block.timestamp;
    }

    // Check-in a bike
    function checkIn(address walletAddress) public {
        require(renters[walletAddress].active == true, "Please check out a bike first");

        renters[walletAddress].active = false;
        // renters[walletAddress].canRent = true;
        renters[walletAddress].end = block.timestamp;

        setDue(walletAddress);
    }

    // Get total duration of bike use
    function renterTimespan(uint start, uint end) internal pure returns(uint){
        return end - start;
    }

    function getTotalDuration(address walletAddress) public view returns(uint){
        require(renters[walletAddress].active == false, "Must check-in your bike first.");
        
        // uint timespan = renterTimespan(renters[walletAddress].start, renters[walletAddress].end);
        // uint timespanInMinutes = timespan / 60;
        return 6;
    }

    // Get contract Balance
    function balanceOf() view public returns(uint) {
        return address(this).balance;
    }

    // Get Renter's balance
    function balanceOfRenter(address walletAddress) view public returns(uint) {
        return renters[walletAddress].balance;
    }
    // Set due amount
    function setDue(address walletAddress) internal {
        uint timespanMinutes = getTotalDuration(walletAddress);
        uint fiveMinuteIncrements = timespanMinutes / 5;

        renters[walletAddress].due = fiveMinuteIncrements * 5000000000000000;
    }

    // Can rent bike
    function canRentBike(address walletAddress) public view returns(bool){
        return renters[walletAddress].canRent;
    }

    // Deposit
    function deposit(address walletAddress) payable public {
        renters[walletAddress].balance += msg.value;
    }

    // Make Payments
    function makePayment(address walletAddress) payable public {
        require(renters[walletAddress].due > 0, "You do not have anything due at this time");
        require(renters[walletAddress].balance > msg.value, "Insufficiant funds to pay due. Deposit funds to be able to pay your due.");

        renters[walletAddress].balance -= msg.value;
        renters[walletAddress].canRent = true;
        renters[walletAddress].due = 0;
        renters[walletAddress].start = 0;
        renters[walletAddress].end = 0;
    }
}