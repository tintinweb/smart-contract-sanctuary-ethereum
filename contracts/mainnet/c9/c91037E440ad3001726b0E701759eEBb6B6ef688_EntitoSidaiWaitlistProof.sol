// SPDX-License-Identifier: MIT

/**
 * @title EntitoSidai Waitlist Proof
 * @author @sidaiLabs
 * @notice Paying the gas fee to join the waitlist is proof of genuine interest in the 
 *         project and helps ensure that only serious participants can mint in the private sale.
 *         This helps prevent the waitlist, which has limited seats,from being filled with 
 *         non-serious participants. The addresses collected here will be used when creating opensea drop.
 */
pragma solidity ^0.8.4;

contract EntitoSidaiWaitlistProof {
    // Waitlist
    mapping(address => bool) public waitlisted;
    uint256 public seatsFilled;
    uint256 public  MAX_SEATS = 500;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Join the waitlist.
     */
    function joinWaitlist() public {
        require(seatsFilled < MAX_SEATS, "Waitlist is full");
        require(!waitlisted[msg.sender], "Already on the waitlist");
        waitlisted[msg.sender] = true;
        seatsFilled++;
    }

     /**
     * @notice Function to set Max waitlist seats.
     */
    function setMaxSeats(uint256 seats) onlyOwner public {
        MAX_SEATS = seats;
    }

    /**
     * @notice Modifier to check if the caller is the contract owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
}