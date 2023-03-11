// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Eventer {

    struct Location {
        address owner;
        string location;
        uint256 capacity;
        string image;
    }

    struct Artist {
        address owner;
        string Name;
    }

    struct Event {
        address owner;
        Location location;
        uint256 date;
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

    function CreateEvent(address _owner, uint256 _location, uint256 _date, 
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

    function RegisterArtist(address owner, string memory name) public returns(uint256)
    {
        Artist storage artist_ = artists[numberOfArtists];

        artist_.Name = name;
        artist_.owner = owner;
        numberOfArtists++;
        return numberOfArtists;
    }

}