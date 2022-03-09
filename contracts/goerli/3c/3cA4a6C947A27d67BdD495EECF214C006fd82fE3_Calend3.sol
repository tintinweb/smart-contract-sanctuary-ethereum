/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Calend3 {
    uint256 rate;
    address payable public owner;

    struct Appointment {
        string title;
        address attendee;
        uint256 startTime;
        uint256 endTime;
        uint256 amountPaid;
    }

    Appointment[] appointments;

    //allows to accept payments
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

    //this function can receive Ether
    function createAppointments(
        string memory _title,
        uint256 _startTime,
        uint256 _endTime
    ) public payable {
        Appointment memory appointment;
        appointment.title = _title;
        appointment.startTime = _startTime;
        appointment.endTime = _endTime;
        appointment.amountPaid = ((_endTime - _startTime) / 60) * rate;
        appointment.attendee = msg.sender; //address of person calling the contract

        require(msg.value >= appointment.amountPaid, "We require more Ether");

        (bool success, ) = owner.call{value: msg.value}(""); // Send ETH to the owner
        require(success, "Failed to send Ether");

        appointments.push(appointment);
    }
}