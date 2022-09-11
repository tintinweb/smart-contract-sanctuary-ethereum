/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem{
    //Record each user location with timestamp
    struct LocationStamp{
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }

    // User fullnames / nicknames
    mapping (address => string) users;

    //Historical locations of all users
    mapping (address => LocationStamp[]) public userLocations;


    // Register username
    function register(string memory userName) public{
        users[msg.sender] = userName;
    }

    //Getter of usernames
    function getPublicName(address userAddress) public view returns (string memory){
        return users[userAddress];
    }

    function track(uint256 lat, uint256 long)public{
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp; //now
        userLocations[msg.sender].push(currentLocation);
    }

    function getLastestLocation(address userAddress) 
    public view returns(uint256 lat, uint256 long, uint256 dateTime){

        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage lastestLocation = locations[locations.length-1];
        return(
            lastestLocation.lat,
            lastestLocation.long,
            lastestLocation.dateTime
        );
        // lat = lastestLocation.lat;
        // long = lastestLocation.long;
        // dateTime =lastestLocation.dateTime;
    }
}