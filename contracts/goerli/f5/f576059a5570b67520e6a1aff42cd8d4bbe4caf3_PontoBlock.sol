// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./EmployeeContract.sol";
import "./UtilContract.sol";

contract PontoBlock {

    struct EmployeeRecord {
        uint256 startWork;
        uint256 endWork;
        uint256 breakStartTime;
        uint256 breakEndTime;
    }

    address owner;
    EmployeeContract private employee;
    UtilContract private util;
    uint private creationDate;
    mapping(address => mapping(uint256 => EmployeeRecord)) private employeeRecords;

    constructor(address _emp, address _util) {
        employee = EmployeeContract(_emp);
        util = UtilContract(_util);
        owner = msg.sender;
        creationDate = util.getDate(block.timestamp);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function startWork() public {
        require(employee.checkIfEmployeeExists(msg.sender), "Employee not registered.");
        require(employeeRecords[msg.sender][util.getDate(block.timestamp)].startWork == 0, "Start of work already registered.");
        employeeRecords[msg.sender][util.getDate(block.timestamp)].startWork = block.timestamp;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function endWork() public {
        require(employee.checkIfEmployeeExists(msg.sender), "Employee not registered.");
        require(employeeRecords[msg.sender][util.getDate(block.timestamp)].endWork == 0, "End of work already registered.");
        require(employeeRecords[msg.sender][util.getDate(block.timestamp)].startWork != 0, "Start of work not registered.");

        uint256 one_hour = 3600;
        if (employeeRecords[msg.sender][util.getDate(block.timestamp)].breakStartTime != 0 &&
            employeeRecords[msg.sender][util.getDate(block.timestamp)].breakEndTime == 0)
        {
                if ((block.timestamp - employeeRecords[msg.sender][util.getDate(block.timestamp)].breakStartTime)
                        > one_hour)
                {
                    employeeRecords[msg.sender][util.getDate(block.timestamp)].breakEndTime =
                        employeeRecords[msg.sender][util.getDate(block.timestamp)].breakStartTime + one_hour;
                }
                else
                {
                    employeeRecords[msg.sender][util.getDate(block.timestamp)].breakEndTime = block.timestamp;
                }
        }

        employeeRecords[msg.sender][util.getDate(block.timestamp)].endWork = block.timestamp;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function breakStartTime() public {
        require(employee.checkIfEmployeeExists(msg.sender), "Employee not registered.");
        require(employeeRecords[msg.sender][util.getDate(block.timestamp)].breakStartTime == 0, "Start of break already registered.");
        require(employeeRecords[msg.sender][util.getDate(block.timestamp)].startWork != 0, "Start of work not registered.");
        require(employeeRecords[msg.sender][util.getDate(block.timestamp)].endWork == 0, "End of work already registered.");

        employeeRecords[msg.sender][util.getDate(block.timestamp)].breakStartTime = block.timestamp;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function breakEndTime() public {
        require(employee.checkIfEmployeeExists(msg.sender), "Employee not registered.");
        require(employeeRecords[msg.sender][util.getDate(block.timestamp)].breakEndTime == 0, "End of break already registered.");
        require(employeeRecords[msg.sender][util.getDate(block.timestamp)].breakStartTime != 0, "Start of break not registered.");

        employeeRecords[msg.sender][util.getDate(block.timestamp)].breakEndTime = block.timestamp;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getCreationDateContract() public view returns(uint) {
        return creationDate;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getEmployeeRecords(address _address, uint256 _date) public view returns (EmployeeRecord memory) {
        require(employee.checkIfEmployeeExists(_address), "Employee not registered.");
        return employeeRecords[_address][_date];
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}