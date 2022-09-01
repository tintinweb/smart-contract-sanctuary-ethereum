//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Hotel {
    uint256 public totalRooms;
    Room[] private rooms;
    address public manager;
    uint256 public roomIds;

    enum Statuses {
        Available,
        Occupied
    }

    event Occupy(address guest, uint256 value);

    constructor(uint256 _totalRooms) {
        manager = msg.sender;
        totalRooms = _totalRooms;
        roomIds = 0;
    }

    mapping(uint256 => Room) public numberToRoom;

    struct Room {
        string description;
        uint256 cost;
        Statuses status;
    }

    modifier OnlyManager() {
        require(msg.sender == manager, "Only Manager");
        _;
    }

    function setTotalRooms(uint256 _totalRooms) public {
        totalRooms = _totalRooms;
    }

    function addRoom(string memory _description, uint256 _cost)
        public
        OnlyManager
    {
        require(rooms.length < totalRooms, "No more rooms");
        require(_cost > 0, "it should cost something..");

        Room memory newRoom = Room({
            description: _description,
            cost: _cost,
            status: Statuses.Available
        });
        rooms.push(newRoom);
        numberToRoom[roomIds] = newRoom;
        roomIds = roomIds + 1;
    }

    function book(uint256 _roomNumber) public payable virtual {
        Room storage room = rooms[_roomNumber];
        require(room.status == Statuses.Available, "Not available");
        require(msg.value >= room.cost, "Not enougth to book");
        room.status = Statuses.Occupied;

        (bool sent, ) = manager.call{value: msg.value}("");
        require(sent, "send failed");

        emit Occupy(msg.sender, msg.value);
    }
}