/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity ^0.5.0;

contract GeoTrackingSysmtem {
    // Record each user location with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }

    mapping (address => LocationStamp[]) public userLocations;

    //user fullnames / nicknames
    mapping (address => string) users;

    function register(string memory userName) public {
        users[msg.sender] = userName;
    }

    function getPublicName(address userAddress) public view returns(string memory) {
        return users[userAddress];
    }

    function me() public view returns(string memory) {
        return users[msg.sender];
    }

    function track(uint256 lat,uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = now;

        userLocations[msg.sender].push(currentLocation);
    }

    function getLatestLocation() public view returns(uint256 lat, uint256 long, uint256 dateTime) {
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length -1];


        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}