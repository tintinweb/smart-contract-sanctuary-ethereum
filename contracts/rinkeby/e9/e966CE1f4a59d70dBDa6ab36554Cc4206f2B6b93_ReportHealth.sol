/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ReportHealth {
    struct Report {
        uint id;
        bool healthy;
        uint timestamp;
    }

    event HealthReported(uint id, bool healthy, uint timestamp);

    // An array of 'Report' structs
    Report[] public reports;

    function create(uint _id, bool _healthy, uint _timestamp) public {
        // 3 ways to initialize a struct
        // - calling it like a function
        reports.push(Report(_id, _healthy, _timestamp));
        emit HealthReported(_id, _healthy, _timestamp);
    }

    // Solidity automatically created a getter for 'todos' so
    // you don't actually need this function.
    function get(uint _index) public view returns (uint _id, bool _healthy, uint _timestamp) {
        Report storage report = reports[_index];
        return (report.id, report.healthy, report.timestamp);
    }
}