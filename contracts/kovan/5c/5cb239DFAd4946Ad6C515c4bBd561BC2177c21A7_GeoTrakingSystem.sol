/**
 *Submitted for verification at Etherscan.io on 2022-03-02
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract GeoTrakingSystem {

    struct LocationStamp{
        uint256 latitude;
        uint256 longitude;
        uint256 datetime;
    }

    mapping(address=>string) users;//address is variable type
    //historical locations of all user
    mapping(address=>LocationStamp[]) public userLocations;

    //register username with sender public address
    function register(string memory userName) public{
        users[msg.sender]=userName;
    }


    function getPublicName(address userAddress) public view returns(string memory){
        return users[userAddress];
    }

    function getMyname() public view returns(string memory){
        return users[msg.sender];
    }

    function track(uint256 lat, uint256 long) public{
        LocationStamp memory currentLocation;
        currentLocation.latitude=lat;
        currentLocation.longitude=long;
        currentLocation.datetime = now;
        userLocations[msg.sender].push(currentLocation);
    }

    /*function getLatestLocation(address userAddress) public view returns(LocationStamp memory latestTrack )
    {
        LocationStamp storage locations= userLocations[userAddress];
        return locations[locations.length-1];
    }*/

    function getLatestLocation(address userAddress) public view returns(uint256 lat, uint256 long, uint256 datetime )
    {
        LocationStamp[] storage locations= userLocations[userAddress];
        LocationStamp storage latestLocation=locations[locations.length-1];
        /*return (
            lat=latestLocation.latitude,
            long=latestLocation.longitude,
            datetime=latestLocation.datetime
        );*/

        //can return too
        lat=latestLocation.latitude;
        long=latestLocation.longitude;
        datetime=latestLocation.datetime;
    }


}