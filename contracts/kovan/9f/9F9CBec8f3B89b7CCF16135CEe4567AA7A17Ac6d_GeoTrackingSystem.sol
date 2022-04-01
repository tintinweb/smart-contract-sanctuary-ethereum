/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem{
    //Record each user location with timestamp
    struct LocationStamp{
        uint256 lat;
        uint256 lng;
        uint256 dateTime;
    }
    //User fullname / nickname
    mapping (address => string) users;

    // Historical location of all users
    mapping (address => LocationStamp[]) public userLocations;

    //Register usersname
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }

    //Getter of username
    function getPublicName(address userAddress) public view returns (string memory){
        return users[userAddress];
    }

    function track(uint256 lat, uint256 lng ) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.lng = lng;
        currentLocation.dateTime = now; // block.timestamp ใช้คำนี้แทนได้
        userLocations[msg.sender].push(currentLocation);
    }

    function getLatesLocation(address userAddress) public view returns(uint256 lat,uint256 lng, uint256 dateTime){
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        // return (
        //     latestLocation.lat,
        //     latestLocation.lng,
        //     latestLocation.dateTime
        // );
        lat = latestLocation.lat;
        lng = latestLocation.lng;
        dateTime = latestLocation.dateTime;

    }
}