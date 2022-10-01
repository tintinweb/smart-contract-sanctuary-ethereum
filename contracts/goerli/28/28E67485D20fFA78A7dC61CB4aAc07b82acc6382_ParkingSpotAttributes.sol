//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ParkingSpotToken {
    function ownerOf(uint) external view returns (address);
}


contract ParkingSpotAttributes {

    event ParkingSpotAvailable(uint256 tokenId, bool available);
    event ParkingSpotInUse(uint256 tokenId, bool inUse);
    event ParkingSpotPermittedTimes(uint256 tokenId, uint8 startHour, uint8 startMinute, uint8 endHour, uint8 endMinute);
    event ParkingSpotPricePerHour(uint256 tokenId, uint256 pricePerHour);

struct availabilityTimes {
    uint8 startHour;
    uint8 startMinute; 
    uint8 endHour; 
    uint8 endMinute;
}

mapping(uint => bool) public spot_available;
mapping(uint=> availabilityTimes) public permittedParkingTime;
mapping(uint=> uint8[2]) public parkingSpotTimeZone;
mapping(uint256=>bool) public spotInUse;
mapping(uint256=>uint256) public pricePerHour;

// Need to make this only owner
address requestParkingSpotTokenAddress;

// Interface address is for local network, must be updated for network deployed to.
// ParkingSpotToken constant pst = ParkingSpotToken(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9);
ParkingSpotToken constant pst = ParkingSpotToken(0x7380e28aB1F6ED032671b085390194F07aBC2606);



function isApprovedOrOwner(uint _parking_spot_id) internal view returns (bool) {
        return pst.ownerOf(_parking_spot_id) == msg.sender;
    }

function setSpotAvailability(uint _parking_spot_id, bool _availability) external {
    require(isApprovedOrOwner(_parking_spot_id), "Not approved to update parking spot Availability"); 
    spot_available[_parking_spot_id] = _availability;
    spotInUse[_parking_spot_id] = false;
    emit ParkingSpotAvailable(_parking_spot_id, _availability);
}

function setSpotPermittedParkingTime(uint _parking_spot_id, uint8 _start_hour, uint8 _start_minute, uint8 _end_hour, uint8 _end_minute) external {
    require(_start_hour <= 23, "Start hour must be between 0 and 23");
    require(_start_minute <= 59, "Start minute must be between 0 and 59");
    require(_end_hour <= 23, "End hour must be between 0 and 23");
    require(_end_minute <= 59, "End minute must be between 0 and 59");

    require(isApprovedOrOwner(_parking_spot_id), "Not approved to update parking spot availability times");
    permittedParkingTime[_parking_spot_id] = availabilityTimes(_start_hour, _start_minute, _end_hour, _end_minute);
    emit ParkingSpotPermittedTimes( _parking_spot_id,  _start_hour,  _start_minute,  _end_hour,  _end_minute);
}

function setParkingSpotTimezone(uint _parking_spot_id, uint8 _isNegative, uint8 _timezone) external {
    require(_timezone <= 14 && _isNegative == 0 || _timezone <= 11 && _isNegative == 1 , "Please input a valid timezone");
    parkingSpotTimeZone[_parking_spot_id] = [_isNegative, _timezone];
}

function setSpotInUse(uint _tokenId, bool _inUse) external {

    spotInUse[_tokenId] = _inUse;
    emit ParkingSpotInUse(_tokenId, _inUse);
}

//make this only owner
function setRequestParkingSpotTokenAddress (address _requestParkingSpotTokenAddress) public {
    requestParkingSpotTokenAddress = _requestParkingSpotTokenAddress;
}

//make this only owner
function setPricePerHour (uint256 _tokenId, uint256 _pricePerHour) public {
    pricePerHour[_tokenId] = _pricePerHour;
    emit ParkingSpotPricePerHour(_tokenId, _pricePerHour);

}

function checkSpotAvailability(uint _parking_spot_id) public view returns (bool) {
    return spot_available[_parking_spot_id];
}

function checkSpotPermittedParkingStartTime(uint _parking_spot_id) public view returns (uint8, uint8) {
    availabilityTimes storage _attr = permittedParkingTime[_parking_spot_id];
    return (_attr.startHour, _attr.startMinute); 
}

function checkSpotPermittedParkingEndTime(uint _parking_spot_id) public view returns (uint8, uint8) {
    availabilityTimes storage _attr = permittedParkingTime[_parking_spot_id];
    return (_attr.endHour, _attr.endMinute); 
}
function checkParkingSpotTimezone(uint _parking_spot_id) public view returns (uint8[2] memory) {
    return parkingSpotTimeZone[_parking_spot_id];
}

}