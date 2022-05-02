/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract GeoTrackingSystem{
    // Record each user location with timestamp
    struct LocationStamp{
        uint256 lat;
        uint256 long;
        uint256 dateTime;

    }

    // User Fullname / nickname / sensor
    mapping (address => string) users;

    //Historical locations of all user
    mapping (address => LocationStamp[]) public userLocations; // ตัวแปรที่ดูว่าจาก Address -> ไปดู LocationStamp

    // Register username
    function register(string memory userName) public {
        users[msg.sender] = userName; //msg.sender คือ คนที่ call เข้ามา ตาม wallet
    }

    // Getter of usernames
    function getPublicName(address userAddress) public view returns(string memory){
        return users[userAddress];
    }

    // Get location แบบที่ต้องระบุ index
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp; // เก็บเวลา ณ ปัจจุบัน
        userLocations[msg.sender].push(currentLocation); // ระบุ 
    }

    // Get location แบบไม่ต้องระบุ index เอาค่าล่าสุด
    function getLastestLocation(address userAddress) public view returns(uint256 lat,uint256 long,uint256 dateTime){
        
        LocationStamp[] storage location = userLocations[msg.sender]; // เพื่อให้เข้าถึง mapping (address => LocationStamp[]) public userLocations; คำสั่งบรรทัดนี้
        LocationStamp storage lastestLocation = location[location.length - 1];

        //return(
        //    lastestLocation.lat,
        //    lastestLocation.long,
        //    lastestLocation.dateTime
        // );

        lat = lastestLocation.lat;
        long = lastestLocation.long;
        dateTime = lastestLocation.dateTime;
    }
}