//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

contract EventContract {
    struct Event {
        address organizer;
        string name;
        uint date;
        uint price;
        uint ticketCount;
        uint ticketRemaining;
    }

    mapping(uint => Event) public events; // nextId => event

    // address of attendee => event Id => no. of tickets bought
    mapping(address => mapping(uint => uint)) public tickets;
    uint public nextId;

    function createEvent(string memory _name, uint _date, uint _price, uint _ticketCount) external {
        require(_date > block.timestamp, "You can organise event at a future date");
        require(_ticketCount > 0, "You can organise event with more than 0 tickets");
        events[nextId] = Event(msg.sender, _name, _date, _price, _ticketCount, _ticketCount);
        nextId++;
    }

    function buyTicket(uint id, uint quantity) external payable {
        require(events[id].date != 0, "This Event doesnt exist");
        require(events[id].date > block.timestamp, "Event has already occured");
        require(events[id].ticketRemaining >= quantity, "Not enough tickets left");
        Event storage _event = events[id];
        require(msg.value == (_event.price * quantity), "Ether is not enough");
        _event.ticketRemaining -= quantity;
        tickets[msg.sender][id] += quantity;
    }

    function transferTicket(uint id, uint quantity, address recipient) external {
        require(events[id].date != 0, "This Event doesnt exist");
        require(events[id].date > block.timestamp, "Event has already occured");
        require(tickets[msg.sender][id] >= quantity, "You dont have enough tickets");
        tickets[msg.sender][id] -= quantity;
        tickets[recipient][id] += quantity;
    }
}