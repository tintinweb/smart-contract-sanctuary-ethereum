/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

pragma solidity ^0.5.0;

// EP 2.6 in skillane.com

contract GeoTrackingSystem{
    //Record eahc user location with timestamp
    struct LocationStamp{
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }

    // Fullname or Nickname of user
    mapping (address => string) users;

    // Historical Location for each user
    mapping (address => LocationStamp[]) public userLocation;

    // Register username
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }

    // Get userName from address
    function getPublicName(address userAddress) public view returns(string memory){
        return users[userAddress];
    }

    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation; //ประกาศตัวแปรใหม่โดยสืบทอดคุณสมบัติมาจาก struct LocationStamp
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp; // หรือ now; ก็ได้
        userLocation[msg.sender].push(currentLocation);
    }

    function getLatestLocation(address userAddress) 
    public view returns (uint256 lat, uint256 long, uint256 dateTime){
        LocationStamp[] storage locations = userLocation[userAddress];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        return (
            latestLocation.lat,
            latestLocation.long,
            latestLocation.dateTime
        );
        //หรือจะ return แบบแทนค่าเข้าตัวแปรได้เลยแบบไม่ใส่คำว่า return โดยที่ชื่อตัวแปรต้องเหมือนกับชื่อที่ return ออกไป
        //lat = latestLocation.lat;
        //long = latestLocation.long;
        //dateTime = latestLocation.dateTime;
    }

}