//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ParkingSpotToken {
    function ownerOf(uint) external view returns (address);
}


contract ParkingSpotAttributes {

struct availabilityTimes {
    uint16 startTime;
    uint16 endTime;
}

mapping(uint => bool) public spot_available;
mapping(uint=> availabilityTimes) public permittedParkingTime;

address private parkingSpotTokenAddress;


constructor (address _parkingSpotTokenAddress) public {
    parkingSpotTokenAddress = _parkingSpotTokenAddress;
}

    ParkingSpotToken immutable pst = ParkingSpotToken(parkingSpotTokenAddress);

function _isApprovedOrOwner(uint _parking_spot_id) internal view returns (bool) {
        return pst.ownerOf(_parking_spot_id) == msg.sender;
    }

function setSpotAvailability(uint _parking_spot_id, bool _availability) external {
    require(_isApprovedOrOwner(_parking_spot_id)); 
    spot_available[_parking_spot_id] = _availability;
}

function setSpotPermittedParkingTime(uint _parking_spot_id, uint16 _start_time, uint16 _end_time) external {
    require(_isApprovedOrOwner(_parking_spot_id));
    permittedParkingTime[_parking_spot_id] = availabilityTimes(_start_time, _end_time);
}

function checkSpotAvailability(uint _parking_spot_id) public view returns (bool) {
    return spot_available[_parking_spot_id];
}

function checkSpotPermittedParkingStartTime(uint _parking_spot_id) public view returns (uint16) {
    availabilityTimes storage _attr = permittedParkingTime[_parking_spot_id];
    return _attr.startTime;
}

function checkSpotPermittedParkingEndTime(uint _parking_spot_id) public view returns (uint16) {
    availabilityTimes storage _attr = permittedParkingTime[_parking_spot_id];
    return _attr.endTime;
}
}