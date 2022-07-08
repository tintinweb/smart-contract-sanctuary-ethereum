//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract EventPool {
    //STATE VARIABLES
    uint256 private eventId;
    uint256 public ETHUSDPrice;
    AggregatorV3Interface internal priceFeed;

    struct Events {
        address admin;
        string name;
        uint256 date; //in number days
        uint256 price;
        uint256 ticketCount;
        uint256 ticketRemaining;

    }

    //EVENTS 
    event CreateEvent(address indexed owner, uint256 indexed price);
    event BuyTicket(address indexed buyer, uint256 _id);
    event SellTicket(address indexed seller, address indexed buyer, uint256 _id);
    

    //MAPPING
    mapping (uint256 => Events) public allEvents;
    mapping (address => mapping(uint256 => uint256)) public tickets;

    //MODIFIERS
    modifier eventOwner(uint256 _id) {
        require(allEvents[_id].admin == msg.sender);
        _;
    }

    constructor() {
       priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }

    function getLatestPrice() public view returns (uint256) {
        (
            ,int256 price,,,
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    
    /**
    @dev create event
     */
    function createEvent(string memory _name, uint256 _date, uint256 _price, uint256 _numberOfTickets) 
    external {
        
        uint256 evDate = block.timestamp + _date;
        allEvents[eventId] = Events(msg.sender, _name, evDate, _price, 0, _numberOfTickets);
        eventId++;

        emit CreateEvent(msg.sender, _price);
    }

    /**
    @dev event owner decides to extend the deadline for the sale of tickets
     */
    function extendDate(uint256 _eventId, uint256 _date) 
    external
    eventOwner(_eventId) {
        uint256 myEventDate = allEvents[_eventId].date;
        assert(_date > myEventDate);
        allEvents[_eventId].date = myEventDate + _date;
    }

    function getETHPrice(uint _amount) 
    internal 
    returns(uint256) {
        ETHUSDPrice =  getLatestPrice() * 10 ** 10; //8 decimal places of the return value

        uint256 ethToUsdAmount = (_amount * ETHUSDPrice) / 10 ** 18;

        return ethToUsdAmount;
    }

    /**
    @dev buys ticket with an input of event id
    @dev uses chainlink price feed to convert between fiat currency USD and ETH

     */
    function buyTicket(uint256 _eventId) 
    external
    payable {
    
        
        
        uint256 ticketPrice = allEvents[_eventId].price * 10 ** 18; //ticket set price for the event
        require(getETHPrice(msg.value) >= ticketPrice); //checks that enough eth
        tickets[msg.sender][_eventId] = tickets[msg.sender][_eventId] + 1; //increment number of ticket for this event
        allEvents[_eventId].ticketCount = allEvents[_eventId].ticketCount + 1;
        allEvents[_eventId].ticketRemaining = allEvents[_eventId].ticketRemaining - 1;
        emit BuyTicket(msg.sender, _eventId);

    }

    function sellTicket(uint256 _eventId, address _beneficiary) 
    external {
        require(tickets[msg.sender][_eventId] > 0); //ensure sender already has a ticket

        tickets[msg.sender][_eventId] = tickets[msg.sender][_eventId] - 1; //derement senders ticket value
        tickets[_beneficiary][_eventId] = tickets[msg.sender][_eventId] + 1; //increment beneficiaries 

        //implement
        emit SellTicket(msg.sender,_beneficiary, _eventId);

    }
    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}