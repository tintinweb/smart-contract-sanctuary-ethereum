/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FEQTicketing {

    // State variables

    address organizer;
    uint ticketPrice;
    uint maxTicketCount;
    uint maxTicketByBuyer;
    bool eventEnded;

    uint ticketsSoldCount;
    mapping(address => uint) buyers;


    // Constructor

    constructor() {
        organizer = msg.sender;
        ticketPrice = 0.01 ether;
        maxTicketCount = 50;
        maxTicketByBuyer = 5;
        eventEnded = false;
        ticketsSoldCount = 0;
    }

    
    // Events

    event TicketsPurchased(address buyer, uint count);


    // Public functions

    function buyTickets(uint ticketCount) public payable returns (uint) {
        // Checks
        require(eventEnded == false, "Event ended");
        
        uint amountToPay = ticketCount * ticketPrice;
        require(msg.value == amountToPay, "Not the right price");

        require(ticketsSoldCount + ticketCount <= maxTicketCount, "Not enough tickets left!");

        require(buyers[msg.sender] + ticketCount <= maxTicketByBuyer, "You have already bought a lot of tickets");

        // Update state variables
        ticketsSoldCount += ticketCount;
        buyers[msg.sender] = buyers[msg.sender] + ticketCount;

        emit TicketsPurchased(msg.sender, ticketCount);

        return ticketCount;
    }

    function getMyTickets() public view returns (uint) {
        return buyers[msg.sender];
    }
    
    function getTicketPrice() public view returns (uint) {
        return ticketPrice;
    }


    // Only organizer functions

    function hasTickets(address buyer) public view onlyOrganizer returns (uint) {
        return buyers[buyer];
    }

    function getSoldCount() public view onlyOrganizer returns (uint) {
        return ticketsSoldCount;
    }

    function endEvent() public onlyOrganizer returns (uint) {        
        uint totalTicketsValue = ticketPrice * ticketsSoldCount;

        eventEnded = false;
        ticketsSoldCount = 0;

        payable(organizer).transfer(totalTicketsValue);

        return totalTicketsValue;
    }

    function getSoldAmount() public view onlyOrganizer returns (uint) {
        return ticketsSoldCount * ticketPrice;
    }


    // Modifiers

    modifier onlyOrganizer() {
        require(organizer == msg.sender, "You're not the organizer");
        _;
    }

}