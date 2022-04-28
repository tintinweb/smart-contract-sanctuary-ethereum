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

    constructor() {
        owner = payable(msg.sender);
    }

    function getRate() public view returns (uint256) {
        return rate;
    }

    function getAppoinments()
        public
        view
        returns (Appointment[] memory _appointments)
    {
        _appointments = appointments;
    }

    function setRate(uint256 _rate) public {
        // TODO: use the openzeppelin access control
        require(msg.sender == owner, "Calend3: not owner");
        rate = _rate;
    }

    function addAppointment(
        string memory _title,
        uint256 _startTime,
        uint256 _endTime
    ) public payable {
        require(rate != 0, "Calend3: rate is zero");
        require((_endTime - _startTime) / 60 > 0, "Calend3: invalid time");
        Appointment memory appointment = Appointment({
            title: _title,
            attendee: msg.sender,
            startTime: _startTime,
            endTime: _endTime,
            amountPaid: ((_endTime - _startTime) / 60) * rate
        });

        require(
            msg.value >= appointment.amountPaid,
            "Calend3: require more eth"
        );

        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Calend3: send fail");

        appointments.push(appointment);
    }
}