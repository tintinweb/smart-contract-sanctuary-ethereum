/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Hotel Reservation
/// @author iammrjude
/// @notice This contract accepts payments from customers that want to book a hotel room
/// @dev Explain to a developer any extra details
contract Hotel {
    address payable public owner;

    Room[] public rooms;

    struct Room {
        string name;
        string description;
        uint256 price;
        RoomStatus currentStatus;
    }
    enum RoomStatus {
        Vacant,
        Occupied
    }

    event RoomBooked(uint256 roomId, address customer, uint256 amountPaid);

    modifier onlyOwner() {
        require(msg.sender == address(owner), "Ownable: caller is not owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function addRoom(
        string memory _name,
        string memory _description,
        uint256 _price
    ) public onlyOwner {
        rooms.push(
            Room({
                name: _name,
                description: _description,
                price: _price,
                currentStatus: RoomStatus.Vacant
            })
        );
    }

    function bookRoom(uint256 roomId, uint256 nights)
        public
        payable
        returns (bool success)
    {
        Room storage room = rooms[roomId];
        require(
            room.currentStatus == RoomStatus.Vacant,
            "room is already booked"
        );
        require(msg.value >= (room.price * nights), "Insufficient funds");

        room.currentStatus = RoomStatus.Occupied;
        (success, ) = owner.call{value: msg.value}("");
        emit RoomBooked(roomId, msg.sender, msg.value);
    }

    function numberOfRooms() public view returns (uint256) {
        return rooms.length;
    }
}