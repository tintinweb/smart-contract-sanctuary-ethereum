/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// 1667023737
// Uncomment this line to use console.log

contract Events {
    struct Event {
        address owner;
        string name;
        uint date;
        uint price;
        uint totalTicket;
        uint ticketAvailable;

    }

    mapping(uint => Event) public events;
    mapping(address => mapping(uint => uint)) public all_tickets;
    uint public indexing;

    function createEvent(
        string memory event_name,
        uint event_date,
        uint event_price,
        uint event_totalTicketCount
    ) external {
        require(
            event_date > block.timestamp,
            "Events event_date can be bigger of today event_date"
        );
        require(
            event_totalTicketCount > 0,
            "Total no. of ticket is greater than 0"
        );
        events[indexing] = Event(
            msg.sender,
            event_name,
            event_date,
            event_price,
            event_totalTicketCount,
            event_totalTicketCount
        );
        indexing++;
    }

    function buyTicket(uint event_id, uint quantity) public payable {
        require(events[event_id].date != 0, "This Event doesn't exists!");
        require(
            events[event_id].ticketAvailable != 0,
            "This Event doesn't exists"
        );
        require(
            events[event_id].ticketAvailable > quantity,
            "This Event ticket doesn't Available!"
        );
        require(
            msg.value > (events[event_id].ticketAvailable * quantity),
            "This Event ticket doesn't Available!"
        );

    
        events[event_id].ticketAvailable -= quantity;
        all_tickets[msg.sender][event_id] += quantity;
    }

    function transferTicket(address to, uint event_id, uint ticket_quantity) external {
        require(events[event_id].date != 0, "This event does not exist");
        require(events[event_id].date > block.timestamp, "Event is already Completed!");
        require(all_tickets[msg.sender][event_id] > ticket_quantity, "You have not enough quantity ticket to send other");

        all_tickets[msg.sender][event_id] -= ticket_quantity;
        all_tickets[to][event_id] += ticket_quantity;
    }
}