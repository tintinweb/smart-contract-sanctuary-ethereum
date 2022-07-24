/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract GeoTackingSystem {
    // Record each user location with timestamp
    struct LocationStamp{
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }

    // User fullnames/nocknames
    mapping(address => string) users;

    // Historical locations of all users
    mapping(address => LocationStamp[]) public userLocations;

    // Register username
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }

    // Getter of usernames
    function getPublicName(address userAddress) public view returns(string memory){
        return users[userAddress];
    }

    // Getter user location
    function track(uint256 lat,uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime =  block.timestamp; //now ; 
        userLocations[msg.sender].push(currentLocation);
    } 

    // Getter location bay address
    function getLatestLocation(address userAddress) public view returns(uint256 lat, uint256 long, uint256 dateTime) {
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length  - 1];
        // return(
        //     latestLocation.lat,
        //     latestLocation.long,
        //     latestLocation.dateTime
        // );
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}