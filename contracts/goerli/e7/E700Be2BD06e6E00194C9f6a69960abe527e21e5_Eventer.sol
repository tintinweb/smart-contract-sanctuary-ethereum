// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Eventer {

    event PaymentReceived(address sender, uint256 amount);
    event TicketPurchased(uint256 eventId, address buyer, uint256 amount);
    event EventPublished(uint256 eventId);
    event ArtistPublished(uint256 artistId);
    event LocationPublished(uint256 locationId);

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
        string Image;
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

    function GetAllEvents() public view returns(Event[] memory)
    {
        Event[] memory allEvents = new Event[](numberOfEvents);
        
        for(uint i = 0; i < numberOfEvents; i++)
        {
            Event storage e = events[i];
            allEvents[i] = e;
        }

        return allEvents;
    }
    
    function GetAllArtists() public view returns(Artist[] memory)
    {
        Artist[] memory allArtists = new Artist[](numberOfArtists);
        
        for(uint i = 0; i < numberOfArtists; i++)
        {
            Artist storage e = artists[i];
            allArtists[i] = e;
        }

        return allArtists;
    }

    function GetAllLocations() public view returns(Location[] memory)
    {
        Location[] memory allLocations = new Location[](numberOfLocations);
        
        for(uint i = 0; i < numberOfLocations; i++)
        {
            Location storage e = locations[i];
            allLocations[i] = e;
        }

        return allLocations;
    }
    

  

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