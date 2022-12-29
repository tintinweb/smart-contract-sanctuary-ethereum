// SPDX-License-Identifier: mit
pragma solidity ^0.8.8;

error EventCanbeCreatedOnlyForFuture();
error CannotCreateLessThanOneTicket();
error NotEnoughEtherSent();
error NotEnoughTicketLeft();
error EventNotExist();
error EventNotActive();

contract EventOrganizer {
    struct Event {
        address admin;
        string name;
        uint256 date;
        uint256 price;
        uint256 ticketCount;
        uint256 ticketRemaining;
    }

    uint256 private nextId;

    address payable private immutable owner;

    mapping(uint256 => Event) private events;
    mapping(address => mapping(uint256 => uint256)) private ticketsOfAddress;

    modifier eventExist(uint256 id) {
        if (events[id].date == 0) {
            revert EventNotExist();
        }
        _;
    }
    modifier eventActive(uint256 id) {
        if (block.timestamp > events[id].date) {
            revert EventNotActive();
        }
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function createEvent(
        string calldata name,
        uint256 date,
        uint256 price,
        uint256 ticketCount
    ) external {
        if (block.timestamp + date <= block.timestamp) {
            revert EventCanbeCreatedOnlyForFuture();
        }
        if (ticketCount <= 0) {
            revert CannotCreateLessThanOneTicket();
        }
        events[nextId] = Event(
            msg.sender,
            name,
            block.timestamp + date,
            price,
            ticketCount,
            ticketCount
        );
        nextId++;
    }

    function buyTicket(uint256 id, uint256 quantity)
        external
        payable
        eventExist(id)
        eventActive(id)
    {
        Event storage _event = events[id];

        if (msg.value != (_event.price * quantity)) {
            revert NotEnoughEtherSent();
        }
        if (_event.ticketRemaining < quantity) {
            revert NotEnoughTicketLeft();
        }
        _event.ticketRemaining -= quantity;
        ticketsOfAddress[msg.sender][id] += quantity;
    }

    function ticketTransfer(
        uint256 eventId,
        uint256 quantity,
        address to
    ) external eventExist(eventId) eventActive(eventId) {
        if (ticketsOfAddress[msg.sender][eventId] < quantity) {
            revert NotEnoughTicketLeft();
        }
        ticketsOfAddress[msg.sender][eventId] -= quantity;
        ticketsOfAddress[to][eventId] += quantity;
    }

    function withdraw() public {
        owner.transfer(address(this).balance);
    }

    function getNextId() public view returns (uint256) {
        return nextId;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getEvents(uint256 _EventId) public view returns (Event memory) {
        return events[_EventId];
    }

    function getTicketsOfAddress(address holder, uint256 eventId)
        public
        view
        returns (uint256)
    {
        return ticketsOfAddress[holder][eventId];
    }
}