// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract EventOrganizer {
    struct Event {
        address admin;
        string name;
        uint256 date;
        uint256 price;
        uint256 ticketCount;
        uint256 ticketRemaining;
    }
    uint256 public nextId;
    mapping(uint256 => Event) public events;
    address payable owner;
    mapping(address => mapping(uint256 => uint256)) public tickets;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier eventExist(uint256 id) {
        require(events[id].date != 0, "event does not exist");
        _;
    }
    modifier eventActive(uint256 id) {
        require(events[id].date > block.timestamp, "event does not exist");
        _;
    }

    function createEvent(
        string memory name,
        uint256 date,
        uint256 price,
        uint256 ticket
    ) public {
        require(
            block.timestamp + date > block.timestamp,
            "event can be only occur in future"
        );
        require(ticket > 0, "ticket must be greater than 0");
        events[nextId] = Event(
            msg.sender,
            name,
            block.timestamp + date,
            price,
            ticket,
            ticket
        );
        nextId++;
    }

    function buyTicket(uint256 id, uint256 quantity)
        public
        payable
        eventExist(id)
        eventActive(id)
    {
        Event storage _event = events[id];
        require(_event.price * quantity >= msg.value, "not enough eth sent");
        require(_event.ticketRemaining >= quantity, "not enough ticker");
        _event.ticketRemaining -= quantity;
        tickets[msg.sender][id] += quantity;
    }

    function transferTicket(
        uint256 id,
        uint256 quantity,
        address to
    ) public eventExist(id) eventActive(id) {
        require(
            tickets[msg.sender][id] >= quantity,
            "sender doesn't have enough ticket"
        );
        tickets[msg.sender][id] -= quantity;
        tickets[to][id] += quantity;
    }

    function withdraw() public {
        require(msg.sender == owner, "owner only");
        owner.transfer(address(this).balance);
    }
}