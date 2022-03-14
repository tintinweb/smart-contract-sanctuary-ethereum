//SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

contract Schedule {
    struct Event {
        uint256 order;
        uint256 startTime;
        uint256 endTime;
        string name;
    }
    struct mySchedule {
        string date;
        mapping(uint256 => Event) myEvents;
    }
    string public name;
    string public date;
    mySchedule private schedule;

    event updatedSchedule(string eventName, uint256 startTime, uint256 endTime);

    constructor(string memory myName, string memory myDate) {
        name = myName;
        date = myDate;
    }
    function addEvent(Event memory newEvent) private {
        schedule.myEvents[(newEvent.order) + 1] = newEvent;
        emit updatedSchedule(newEvent.name, newEvent.startTime, newEvent.endTime);
    }
}