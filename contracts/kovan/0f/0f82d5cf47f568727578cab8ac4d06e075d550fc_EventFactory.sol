pragma solidity ^0.5.0;

import "./Event.sol";

/**
@title Event factory */
contract EventFactory {
    /**
        @dev created and deployed new event and saves it in the event list array
        @param _name title of the event to be created 
        @param start start date of event in unix timestamp
        @param end end date of event in unix timestamp 
        @param supply total supply of event ticket available for the event
        @param ticketPrice price of single ticket price in wei
        @param description description of the event 
        @param location location of the event
        @return emits eveneCreated log
        */
    bool private halted;
    address private owner;
    Event[] public deployedEvents;
    event eventCreated(
        Event _address,
        string event_title,
        string event_website,
        string event_description,
        uint256 event_start,
        uint256 ticket_price,
        uint256 number_tickets,
        string indexed _filterName
    );

    function createEvent(
        string memory event_title,
        string memory event_website,
        string memory event_description,
        uint256 event_start,
        uint256 ticket_price,
        uint256 number_tickets
    ) public {
        require(!halted);
        address payable sender = msg.sender;
        Event newEvent = new Event(
            sender,
            event_title,
            event_website,
            event_description,
            event_start,
            ticket_price,
            number_tickets
        );
        deployedEvents.push(newEvent);
        emit eventCreated(
            newEvent,
            event_title,
            event_website,
            event_description,
            event_start,
            ticket_price,
            number_tickets,
            event_title
        );
    }

    /**
    @dev returns list of event addresses
    @return deployedEvents array of event address */
    function getDeployedEvents() public view returns (Event[] memory) {
        return deployedEvents;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only the owner can perform this task");
        _;
    }
}