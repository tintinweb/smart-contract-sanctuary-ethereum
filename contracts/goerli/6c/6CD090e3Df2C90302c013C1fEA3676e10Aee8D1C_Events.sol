// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Roles.sol";

contract Events is Roleable {
    struct EventData {
        address organizer;
        string title;
        uint256 bonus;
        string description;
        string status;
        string dateStart;
        string dateEnd;
    }

    mapping(string => EventData) public events;

    constructor() {
        owner = msg.sender;
    }

    function createEvent(
        string memory _id,
        address organizer,
        string memory _title,
        uint256 _bonus,
        string memory _description,
        string memory _status,
        string memory _dateStart,
        string memory _dateEnd
    ) public onlyOwnerOrAdmin {
        events[_id] = EventData({
            organizer: msg.sender,
            title: _title,
            bonus: _bonus,
            description: _description,
            status: _status,
            dateStart: _dateStart,
            dateEnd: _dateEnd
        });
    }

    // function updateEvent(
    //     string memory _id,
    //     string memory _title,
    //     string memory _description,
    //     string memory _link,
    //     string memory _status,
    //     string memory _timestamp
    // ) public onlyAdminOrManager {
    //     events[_id].title = _title;
    //     events[_id].description = _description;
    //     events[_id].link = _link;
    //     events[_id].status = _status;
    //     events[_id].timestamp = _timestamp;
    // }

    function removeEvent(string memory _id) public onlyAdmin {
        delete events[_id];
    }
}