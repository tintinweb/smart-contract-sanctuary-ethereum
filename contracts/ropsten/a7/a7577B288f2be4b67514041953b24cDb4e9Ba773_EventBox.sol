/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

pragma solidity >=0.8.0 <0.9.0;

contract EventBox {

  // Event creator data (1 creator of ALL events)
  address payable public eventsCreator;
  uint[] public eventsIDs; // To show all of events on the frontend page (Events.js)
  bool internal isEntry = false; // boolean for reentrency security

  // Event data
  struct Event {
    string title;
    string description;
    uint eventEndTime;
    uint eventEndValue;
    uint currentValue;
    EventState currentState;
  }

  // Mapping of all events (event id and Event mapping)
  mapping(uint => Event) public events;

  // Mapping of all users (user address -> (event id -> user funds) mapping)
  mapping(address => mapping(uint => uint)) public userFunds;

  // Current state of event (definition)
  enum EventState {Default, Running, Canceled, TimeEnded, Completed}

  constructor() {
    eventsCreator = payable(msg.sender);
  }

  modifier notEventsCreator(){
    require(msg.sender != eventsCreator, "You are the events creator! Events creator can't do it!");
    _;
  }

  modifier onlyEventsCreator(){
    require(msg.sender == eventsCreator, "You are not the events creator!");
    _;
  }

  modifier nonZeroFunds(){
    require(msg.value > 0, "Funds can be only greater, than 0!");
    _;
  }

  // for reentrency security
  modifier noReentrant(){
    require(isEntry == false, "This function is already running!");
    isEntry = true;
    _;
    isEntry = false;
  }

  // Creating new event and add it to the event list
  function createEvent(
    string memory _title,
    string memory _description,
    uint _eventId,
    uint _eventEndTime,
    uint _eventEndValue
  ) public onlyEventsCreator{
    require(events[_eventId].currentState == EventState.Default, "Take another id!");
    require(_eventEndValue > 0, "Event value need to be more than 0!");

    Event memory newEvent = Event({
      title: _title,
      description: _description,
      eventEndTime: block.timestamp + _eventEndTime,
      eventEndValue: _eventEndValue * 10**18,
      currentValue: 0,
      currentState: EventState.Running
    });

    events[_eventId] = newEvent;
    eventsIDs.push(_eventId);
  }

  // get event info with needed address
  function getEvent(uint _eventId) public view returns(Event memory) {
    return events[_eventId];
  }

  function getEventsCreator() public view returns (address) {
    return eventsCreator;
  }

  function getEventsIDs() public view returns (uint[] memory) {
    return eventsIDs;
  }

  // Participant send funds
  function fundingToEvent(uint _eventId) public payable notEventsCreator nonZeroFunds{
    require(events[_eventId].currentState == EventState.Running, "Event not running!");  
    require(events[_eventId].currentValue < events[_eventId].eventEndValue, "Event has enough funds!");
    require(block.timestamp <= events[_eventId].eventEndTime, "Event has no time!");

    events[_eventId].currentValue += msg.value;
    userFunds[msg.sender][_eventId] += msg.value;

    if (events[_eventId].currentValue >= events[_eventId].eventEndValue) {
      events[_eventId].currentState = EventState.Completed;
      bool isSend = eventsCreator.send(events[_eventId].currentValue);
      require(isSend, "Error to send funds to creator");
    }
  }

  // Creator can cancel event
  function cancelEvent(uint _eventId) public onlyEventsCreator {
    require(events[_eventId].currentState == EventState.Running, "Event not running!");
    require(events[_eventId].currentValue < events[_eventId].eventEndValue, "Event has enough funds!");

    events[_eventId].currentState = EventState.Canceled;
  }

  // Participant can return his money if event was not completed
  function returnFundsBack(uint _eventId) public notEventsCreator noReentrant {
    require(events[_eventId].currentState != EventState.Completed, "Event completed yet!");

    address payable toReturnAddr =  payable(msg.sender);    
    uint pendingFunds = userFunds[msg.sender][_eventId];

    bool isSend = toReturnAddr.send(pendingFunds);
    require(isSend, "Error to return your funds");

    events[_eventId].currentValue -= pendingFunds;

    delete userFunds[msg.sender][_eventId];
  }

  function timeCloseEvent(uint _eventId) public onlyEventsCreator{
    require(events[_eventId].currentState == EventState.Running, "Event not running!");
    require(block.timestamp >= events[_eventId].eventEndTime, "Event still has time!");

    events[_eventId].currentState = EventState.TimeEnded;
  }
}