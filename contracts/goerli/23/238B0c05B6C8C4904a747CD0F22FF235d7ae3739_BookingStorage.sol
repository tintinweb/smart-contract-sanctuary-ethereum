// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BookingStorage {
    address public roomOwner;

    constructor() {
        roomOwner = msg.sender;
        currentStatus = RoomStauts.vacant;
    }

    enum RoomStauts {
        vacant,
        occupied
    }

    RoomStauts public currentStatus;

    function book() public {
        require(currentStatus == RoomStauts.vacant, "Currently occupied");
        currentStatus = RoomStauts.occupied;
    }

    function getRoomOwner() public view returns (address) {
        return roomOwner;
    }
}