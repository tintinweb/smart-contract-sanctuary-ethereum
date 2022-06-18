/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

pragma solidity ^0.5.0;

contract GeoTrakingSystem {
    // Record each user location with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }

    // User fullname / nickname
    mapping (address => string) users;


    //Histotical location of all users
    mapping (address => LocationStamp[]) public userLocations;

    // Register username 
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }

    // Getter of usernames
    function getPublicName(address userAddress) public view returns(string memory){
        return users[userAddress];
    }

    function track(uint256 lat, uint long) public {
        LocationStamp memory currentLocation;

        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = now; //block.timestamp;
        userLocations[msg.sender].push(currentLocation);
    }

    function getLatesLocation(address userAddress) public view returns (uint256 lat, uint256 long, uint256 dateTime){
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latesLocation = locations[locations.length - 1];

        // return (
        //     latesLocation.lat,
        //     latesLocation.long,
        //     latesLocation.dateTime
        // );

        lat = latesLocation.lat;
        long = latesLocation.long;
        dateTime = latesLocation.dateTime;
    }
}