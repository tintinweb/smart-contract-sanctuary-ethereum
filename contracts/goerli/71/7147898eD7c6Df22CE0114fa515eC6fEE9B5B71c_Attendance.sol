/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: MIT

pragma solidity^0.8.0;

contract Attendance{
    uint256 id;
    address owner;
    uint256 openTime;
    uint256 openingDuration;
    mapping (uint256 => mapping (address => bool) ) private userAttendance;

    modifier isOwner(){
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    //write the duration in seconds
    function openAttendancesList(uint256 _openingDuration) public isOwner(){
        openingDuration = _openingDuration;
        openTime = block.timestamp;
    }

    function confirmAttendance() public {
        require((openTime + openingDuration) >= block.timestamp, "Attendances list is currently closed");
        userAttendance[id][msg.sender] = true;
    }

    function createClass() public isOwner(){
        id++;
    }

    function getTimeLeft() public view returns(uint256){
        require((openTime + openingDuration) >= block.timestamp, "Attendances list is currently closed");
        return (openTime + openingDuration - block.timestamp);
    }

    function getClass() public view returns(uint256){
        return id;
    }

    function getAttendances(uint256 id_, address alumn) public view isOwner() returns(bool){
        require (id_ <= id, "This class does not exist");
        return userAttendance[id_][alumn];
    }
}