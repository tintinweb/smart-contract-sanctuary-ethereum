// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Eventer {

    event PaymentReceived(address sender, uint256 amount);



    struct Location {
        address payable owner;
        string name;
        string location;
        uint256 capacity;
        string image;
    }

    struct Artist {
        address payable owner;
        string Name;
    }

    struct Event {
        address payable owner;
        Location location;
        uint256 date;
        uint256 price;
        string title;
        string description;
        Artist artist;
        string image;
        address[] ticketHolders;
        uint256 ticketsSold;
    }

    mapping(uint256 => Event) public events;

    mapping(uint256 => Location) public locations;

    mapping(uint256 => Artist) public artists;

    
    uint256 public numberOfEvents = 0;
    uint256 public numberOfArtists = 0;
    uint256 public numberOfLocations = 0;

    function CreateEvent(address payable _owner, uint256 _location, uint256 _date, 
    string memory _title,string memory _description, uint256 _artist, 
    string memory _image) public returns (uint256)
    {
        Event storage event_ = events[numberOfEvents];

        event_.owner = _owner;
        event_.location = locations[_location];
        event_.date = _date;
        event_.title = _title;
        event_.description = _description;
        event_.artist = artists[_artist];
        event_.image = _image;
        event_.ticketsSold = 0;
        numberOfEvents ++;
        return numberOfEvents-1;
    }

    function RegisterArtist(address payable owner, string memory name) 
    public returns(uint256)
    {
        Artist storage artist_ = artists[numberOfArtists];

        artist_.Name = name;
        artist_.owner = owner;

        numberOfArtists++;
        return numberOfArtists-1;
    }

    function RegisterLocation(address payable owner, string memory name, string memory location, uint256 capacity, string memory image)
    public returns(uint256)
    {
        Location storage location_ = locations[numberOfLocations];
        
        location_.owner = owner;
        location_.name = name;
        location_.location = location;
        location_.capacity = capacity;
        location_.image = image;

        numberOfLocations++;
        return numberOfLocations-1;
    }

    function RegisterEvent(address payable owner, uint256 location, uint256 date, uint256 price,
    string memory title, string memory description, uint256 artist, string memory image)
    public returns(uint256)
    {
        Event storage event_ = events[numberOfEvents];

        event_.owner = owner;
        event_.location = locations[location];
        event_.date = date;
        event_.price = price;
        event_.title = title;
        event_.description = description;
        event_.artist = artists[artist];
        event_.image = image;
        event_.ticketsSold = 0;

        numberOfEvents++;
        return numberOfEvents-1;
    }


  

  event TicketPurchased(uint256 eventId, address buyer, uint256 amount);

  function BuyTicket(address payable buyer, uint256 eventId) 
  public payable returns (uint256) {
    Event storage event_ = events[eventId];
    address payable event_address = event_.owner;

    require(event_.price == msg.value, "Incorrect ticket price");

    event_address.transfer(msg.value);
    event_.ticketsSold++;
    event_.ticketHolders.push(buyer);

    emit TicketPurchased(eventId, buyer, msg.value);

    return event_.ticketsSold-1;
  }
    
    

}