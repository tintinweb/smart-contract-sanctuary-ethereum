/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem{
    //Record each user location with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    //User fullname / nickname
    mapping (address => string) users;

    //Historical locations of all users
    mapping (address => LocationStamp[]) public userLocations;

    //register username
    function register(string memory userName) public{
        users[msg.sender] = userName;
    }

    //Getter of usernames
    function getPublicName(address userAddress) 
    public view returns(string memory){
        return users[userAddress];
    }

    function track(uint256 lat,uint256 long) public{
        LocationStamp memory currenctLocation;
        currenctLocation.lat = lat;
        currenctLocation.long = long;
        currenctLocation.dateTime = now; //block.timestamp;
        userLocations[msg.sender].push(currenctLocation);
    }

    function getLatestLocation(address userAddress) 
        public view returns (uint256 lat,uint256 long,uint256 dateTime){
            LocationStamp[] memory locations = userLocations[msg.sender];
            LocationStamp memory latestLocation = locations[locations.length - 1];
            //return (
            //    latestLocation.lat,
            //    latestLocation.long,
            //    latestLocation.dateTime
            //);
            lat = latestLocation.lat;
            long = latestLocation.long;
            dateTime = latestLocation.dateTime;
    }
}