// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Calend3 {
    uint256 rate;
    address payable public owner; // payable allows to receive money

    struct Appointment {
        string title;
        address attendee;
        uint256 startTime;
        uint256 endTime;
        uint256 amountPaid;
    }

    Appointment[] appointments;

    constructor() {
        owner = payable(msg.sender);
    }

    function getRate() public view returns (uint256) {
        return rate;
    }

    function setRate(uint256 _rate) public {
        require(msg.sender == owner, "Only the owner can set the rate");
        rate = _rate;
    }

    function getAppointments() public view returns (Appointment[] memory) {
        return appointments;
    }

    function createAppointment(
        string memory title,
        uint256 startTime,
        uint256 endTime
    ) public payable {
        Appointment memory appointment;
        appointment.title = title;
        appointment.startTime = startTime;
        appointment.endTime = endTime;
        appointment.amountPaid = ((endTime - startTime) / 60) * rate;

        require(msg.value >= appointment.amountPaid, "We require more ether");
        (bool success, ) = owner.call{value: msg.value}(""); // send ETH to the owner
        require(success, "Failed to send Ether");
        appointments.push(appointment);
    }
}