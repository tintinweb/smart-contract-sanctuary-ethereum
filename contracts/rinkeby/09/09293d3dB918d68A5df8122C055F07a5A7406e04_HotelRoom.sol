//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HotelRoom {
    enum Statuses {
        Vacant,
        Occupied
    }

    Statuses public currentStatus;

    event Occupy(address _occupant, uint256 _value);

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
        currentStatus = Statuses.Vacant;
    }

    modifier OnlyWhileVacant() {
        require(currentStatus == Statuses.Vacant, "Currently occupied.");
        _;
    }

    function Book(uint256 _value) public payable OnlyWhileVacant {
        currentStatus = Statuses.Occupied;
        _value = 0.001 ether;

        (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        require(sent);

        emit Occupy(msg.sender, msg.value);
    }
}