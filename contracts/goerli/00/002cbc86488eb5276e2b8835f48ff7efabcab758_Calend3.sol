/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract Calend3 {
     uint appointmentRate;
     address payable public owner;

     struct Appointment {
         string title;
         address attendee;
         uint startTime;
         uint endTime;
         uint amountPaid;
     }

     Appointment[] appointments;

     constructor() {
         owner = payable(msg.sender);
     }

     function getAppointmentRate() public view returns (uint) {
         return appointmentRate;
     }

     function setAppointmentRate(uint _appointmentRate) public {
         require(msg.sender == owner, "Only the owner can set the rate");
         appointmentRate = _appointmentRate;
     }

     function getAppointments() public view returns (Appointment[] memory) {
         return appointments;
     }

     function createAppointment(string memory _title, uint _startTime, uint _endTime) public payable {
         Appointment memory appointment;
         appointment.title = _title;
         appointment.startTime = _startTime;
         appointment.endTime = _endTime;
         appointment.amountPaid = ((_endTime - _startTime) / 60) * appointmentRate;
         appointment.attendee = msg.sender;

         require(msg.value >= appointment.amountPaid, "We require more ether");
         (bool success,) = owner.call{ value: msg.value }("");
         require(success, "Failed to send Ether");

         appointments.push(appointment);
     }
}