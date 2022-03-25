/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem{

    // record each user location with timestamp
    struct LocationStamp{
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    } 

    // User fullName 
    mapping(address => string) users;

    // History locations of all user
    mapping(address => LocationStamp []) public userLocations;


    // Register username
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }

    // Getter for user
    function getPublicName(address userAddress) public view returns(string memory){
        return users[userAddress];
    }

    function track(uint256 latParm,uint256 longParm) public {
        LocationStamp memory currentLocation;
        
        currentLocation.lat = latParm;
        currentLocation.long = longParm;
        currentLocation.dateTime = now; // block timestamp

        userLocations[msg.sender].push(currentLocation);

    }

    function getLastedLocation(address userAddress) public view returns (uint256 lat,uint256 long, uint256 dateTime){
        LocationStamp[] storage locations = userLocations[msg.sender];
        
        LocationStamp storage lastedLocation = locations[locations.length -1];


        lat      = lastedLocation.lat;
        long     = lastedLocation.long;
        dateTime = lastedLocation.dateTime;
    }

}