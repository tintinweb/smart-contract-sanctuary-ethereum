/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract EventContract {
    struct Event{
        address organiser;
        string name;
        uint date;
        uint price;
        uint ticketCount;
        uint ticketRemaining;
    }

    mapping(uint => Event) public events;
    mapping (address => mapping(uint => uint)) public tickets;
    uint public nextId;

    modifier validateEvent(uint _id) {
        require(events[_id].date != 0, "These event does not exist");
        require(events[_id].date > block.timestamp, "Event has already occured");
        _;
    }

    function createEvenet(string memory name, uint date, uint price, uint ticketCount) external {
        require(date > block.timestamp, "You can only organise event for feature event");
        require(ticketCount > 0, "Ticket count must be more than 0");
        events[nextId] = Event(msg.sender, name, date, price, ticketCount, ticketCount);
        nextId++;
    }

    function buyTicket(uint _id, uint _quantity) payable validateEvent(_id) external {
        Event storage _event = events[_id];
        require(msg.value==(_event.price * _quantity), "Ether not enough");
        require(_event.ticketRemaining>=_quantity, "Not enough tickets remaining");
        _event.ticketRemaining -= _quantity;
        tickets[msg.sender][_id] += _quantity;
    }

    function transferTicker(address _to, uint _quantity, uint _id) external validateEvent(_id) {
        require(tickets[msg.sender][_id] >= _quantity, "You dont have enough tickets");
        tickets[msg.sender][_id] -= _quantity;
        tickets[_to][_id] += _quantity;
    }
}