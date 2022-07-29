//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ParkingSpotToken {
    function ownerOf(uint) external view returns (address);
}

contract ParkingSpotAttributes {
    ParkingSpotToken constant pst = ParkingSpotToken(0xaE35231E1919b0A1922DE02782D4c4DccD18c782);


mapping(uint => bool) public spot_available;

  function _isApprovedOrOwner(uint _parking_spot_id) internal view returns (bool) {
        return pst.ownerOf(_parking_spot_id) == msg.sender;
    }

function setSpotAvailability(uint _parking_spot_id, bool _availability) external {
    require(_isApprovedOrOwner(_parking_spot_id)); 
    spot_available[_parking_spot_id] = _availability;
}

function checkSpotAvailability(uint _parking_spot_id) public view returns (bool) {
    return spot_available[_parking_spot_id];
}
}