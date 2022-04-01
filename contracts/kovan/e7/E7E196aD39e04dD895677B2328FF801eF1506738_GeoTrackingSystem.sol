/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem{

    struct Locationstamp{
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    //user (name)
    mapping(address=>string) users;
    //historical locations of all users
    mapping(address=>Locationstamp[])public userLocations; 
    //register user
    function register(string memory userName) public{
        users[msg.sender]=userName;

    }
    //getter fo  usernames
    function getPublicName(address userAddress) public view returns(string memory){
        return users[userAddress];
    }
    function track(uint256 lat,uint256 long) public{
        Locationstamp memory currentLocation;
        currentLocation.lat=lat;
        currentLocation.long=long;
        currentLocation.dateTime= now;  //block.timestapm

        userLocations[msg.sender].push(currentLocation);
    }
    function getLastestLocation(address userAddress) 
    public view returns(uint256 lat,uint256 long,uint256 dateTime){
        Locationstamp[] storage locations=userLocations[msg.sender];
        Locationstamp storage lastestLocation = locations[locations.length-1];
        return (
            lastestLocation.lat,
            lastestLocation.long,
            lastestLocation.dateTime
        );
        //lat.lastestLocation;
       // long.lastestLocation;
       // dateTime.lastestLocation;
    }
}