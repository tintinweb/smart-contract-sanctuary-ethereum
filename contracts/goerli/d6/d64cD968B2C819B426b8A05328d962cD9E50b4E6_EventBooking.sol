// SPDX-License-Identifier: MTI
pragma solidity ^0.8.9;

contract EventBooking {
    string public name;
    bytes32 public symbol;
    address owner;
    uint256 public numberOfEvents = 0;
    
    struct Event {
        address creator;
        string title;
        string description;
        uint256 amount;
        uint256 eventDate;
        string image;
        uint256 price;
        string category;
        string eventAddress;
        string eventLocation;
        address[] buyer;
        uint256[] tickets;
    }

    mapping(uint256 => Event) public events;

    constructor() {
        name = "Graphie Event Booking";
        symbol = "GVBO";
        owner = msg.sender;
    }

    function createEvent(
        string memory _title, 
        string memory _description, 
        uint256 _amount, 
        uint256 _eventDate, 
        uint256 _price,
        string memory _image,
        string memory _category,
        string memory _eventAddress,
        string memory _eventLocation
    ) public returns (uint256) {
        Event storage _event = events[numberOfEvents];

        // require(_eventDate > block.timestamp, "The event date should be a date in the future.");
        require(_eventDate > block.timestamp, "The deadline should be a date in the future.");

        _event.creator = msg.sender;
        _event.title = _title;
        _event.description = _description;
        _event.amount = _amount;
        _event.eventDate = _eventDate;
        _event.price = _price;
        _event.image = _image;
        _event.category = _category;
        _event.eventAddress = _eventAddress;
        _event.eventLocation = _eventLocation;

        numberOfEvents++;

        return numberOfEvents - 1;
    }

    function getEvents() public view returns (Event[] memory) {
        Event[] memory AllEvents = new Event[](numberOfEvents);

        for(uint i = 0; i < numberOfEvents; i++) {
            Event storage item = events[i];

            AllEvents[i] = item;
        }

        return AllEvents;
    }

     function getSingleEvent(uint256 _id) public view returns (Event memory) {
        return events[_id];
    }

    function bookingEvent(uint256 _id, uint256 _amount) public payable {
    
        Event storage _event = events[_id];
        uint256 _value = msg.value;
        uint256 _eventDate = _event.eventDate;
        uint256 _price = (_event.price * _amount);

        require(_event.amount >= _amount, "insufficient ticket quota");
        require(_eventDate > block.timestamp, "Event has passed.");
        require(_price == _value, "Prices don't match.");

        _event.buyer.push(msg.sender);
        _event.tickets.push(_amount);

        (bool sent,) = payable(_event.creator).call{value: _value}("");

        if(sent) {
            _event.amount = _event.amount - _amount;
        }
    }

    function getBuyers(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (events[_id].buyer, events[_id].tickets);
    }

    function addTicketAllocation(uint256 _id, uint256 _amount) public {
        Event storage _event = events[_id];
        require(_event.creator == msg.sender, "only creators can add ticket quotas.");
        require(_amount > 0, "Amount cannot be 0");
        _event.amount = _event.amount + _amount;
    }

    function subtractionTicketAllocation(uint256 _id, uint256 _amount) public {
        Event storage _event = events[_id];
        require(_event.creator == msg.sender, "only creators can reduce the ticket quota.");
        require(_amount > 0, "Amount cannot be 0");
        _event.amount = _event.amount - _amount;
    }

}