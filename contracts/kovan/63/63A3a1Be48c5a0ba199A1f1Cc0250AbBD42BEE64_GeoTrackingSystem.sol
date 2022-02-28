/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GeoTrackingSystem {
    // Record each user location with timestamp
    struct LocationStamp{
        uint256 lat;        uint256 long;
        uint256 dateTime;
    }

    // user fullname / nicknames
    mapping(address => string ) users;

    // Historical location of all users
    mapping(address => LocationStamp[]) public userLocations;

    // Register username
    function register(string memory userName) public {
        // msg is build in from smart contract use for get value eg. sender address of calle
        // caller adjust by public/private key of user
        users[msg.sender] = userName;
    }

    // Getter of usernames
    function getPublicName(address userAddress) public view returns (string memory){
        return users[userAddress];
    }

    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation ;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp;
        userLocations[msg.sender].push(currentLocation);
    }

    function getLatestLocation(address userAddress) public view returns ( uint256 lat , uint256 long , uint256 dateTime){
        // use storage: access value of locations not create new one
        LocationStamp[] storage locations = userLocations[userAddress];
        LocationStamp storage latestLocation = locations[locations.length - 1];

        // return (
        //     latestLocation.lat,
        //     latestLocation.long,
        //     latestLocation.dateTime
        // );
        // or

        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }

}