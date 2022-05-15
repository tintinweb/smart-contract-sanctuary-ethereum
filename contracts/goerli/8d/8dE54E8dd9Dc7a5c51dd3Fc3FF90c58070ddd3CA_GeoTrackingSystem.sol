/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract GeoTrackingSystem {
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }

    mapping (address => string) users;

    mapping (address => LocationStamp[]) public userLocations;

    function register(string memory userName) public {
        users[msg.sender] = userName;
    }

    function getPublicName(address userAddress) public view returns (string memory){
        return users[userAddress];
    }

    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = now; // block.timestamp
        userLocations[msg.sender].push(currentLocation);
    }

    function getLatestLocation(address userAddress) public view returns (uint256 lat, uint256 long, uint256 dateTime){
        LocationStamp[] storage locations = userLocations[userAddress];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        // return (
        //     latestLocation.lat,
        //     latestLocation.long,
        //     latestLocation.dateTime
        // );
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}