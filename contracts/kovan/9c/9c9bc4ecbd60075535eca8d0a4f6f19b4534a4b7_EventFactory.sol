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
    event eventCreated(Event _address, string _name, uint _ticketPrice, string location, uint startDate, uint endDate, string indexed _filterName, string indexed _filterLocation);



    function createEvent(string memory  _name, uint _start, uint _end,  uint supply, uint _ticketPrice, string memory _description, string memory _location) public  {
        require(!halted);
        address payable sender = msg.sender;
        Event newEvent = new Event(sender, _name, _start, _end,_description, _location, supply, _ticketPrice );
        deployedEvents.push(newEvent);
        emit eventCreated(newEvent, _name, _ticketPrice, _location, _start, _end, _name, _location);

    }

    /**
    @dev returns list of event addresses
    @return deployedEvents array of event address */
   function getDeployedEvents() public view returns(Event[] memory) {
        return deployedEvents;
    }



    modifier onlyOwner {
        require(msg.sender == owner, "only the owner can perform this task");
        _;
    }
    
    
}