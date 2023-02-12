// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./EmployeeContract.sol";
import "./PontoBlock.sol";
import "./UtilContract.sol";

contract PontoBlockReports {

    EmployeeContract private employee;
    PontoBlock private pontoBlock;
    UtilContract private util;

    constructor(address _emp, address _ponto, address _util) {
        employee = EmployeeContract(_emp);
        pontoBlock = PontoBlock(_ponto);
        util = UtilContract(_util);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getWorkTimesFromEmployeeAtDate(address _employee, uint256 _date) public view
        returns (
                 uint256 _startWork,
                 uint256 _endWork,
                 uint256 _breakStartTime,
                 uint256 _breakEndTime
                ) {

        require(employee.checkIfEmployeeExists(_employee), "Employee not registered.");

        PontoBlock.EmployeeRecord memory record = pontoBlock.getEmployeeRecords(_employee, _date);
        _startWork = record.startWork;
        _endWork = record.endWork;
        _breakStartTime = record.breakStartTime;
        _breakEndTime = record.breakEndTime;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getWorkTimeFromEmployeeBetweenTwoDates(address _employee, uint256 _startDate, uint256 _endDate) public view
        returns (
                 uint256[] memory _date,
                 uint256[] memory _startWork,
                 uint256[] memory _endWork,
                 uint256[] memory _breakStartTime,
                 uint256[] memory _breakEndTime
                ) {

        require(employee.checkIfEmployeeExists(_employee) == true, "Employee not registered.");
        require(_startDate < _endDate, "Start date must be less than end date.");
        require(_startDate >= pontoBlock.getCreationDateContract(), "Start date must be equals or grather than creationDate.");
        require(_endDate <= util.getDate(block.timestamp), "End date must be equals or less than today.");

        _date = new uint256[](_endDate - _startDate);
        _startWork = new uint256[](_endDate - _startDate);
        _endWork = new uint256[](_endDate - _startDate);
        _breakStartTime = new uint256[](_endDate - _startDate);
        _breakEndTime = new uint256[](_endDate - _startDate);

        address add = _employee;
        uint256 j = 0;
        for (uint256 i = _startDate; i <= _endDate; i++) {
            PontoBlock.EmployeeRecord memory record = pontoBlock.getEmployeeRecords(add, i);
            _date[j] = i;
            _startWork[j] = record.startWork;
            _endWork[j] = record.endWork;
            _breakStartTime[j] = record.breakStartTime;
            _breakEndTime[j] = record.breakEndTime;
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getWorkTimesForAllEmployeesAtDate(uint256 _date) public view
        returns (
                 address[] memory _empAddress,
                 uint256[] memory _startWork,
                 uint256[] memory _endWork,
                 uint256[] memory _breakStartTime,
                 uint256[] memory _breakEndTime
                ) {

        require(_date >= pontoBlock.getCreationDateContract(), "Start date must be equals or grather than creationDate.");

        EmployeeContract.Employee[] memory allEmployees = employee.getAllEmployees();

        _empAddress = new address[](allEmployees.length);
        _startWork = new uint256[](allEmployees.length);
        _endWork = new uint256[](allEmployees.length);
        _breakStartTime = new uint256[](allEmployees.length);
        _breakEndTime = new uint256[](allEmployees.length);

        uint256 date = _date;

        for (uint256 i = 0; i < allEmployees.length; i++) {
            _empAddress[i] = allEmployees[i].employeeAddress;
            (uint256 _startW, uint256 _endW, uint256 _breakStartT, uint256 _breakEndT) =
                getWorkTimesFromEmployeeAtDate(_empAddress[i], date);
            _startWork[i] = _startW;
            _endWork[i] = _endW;
            _breakStartTime[i] = _breakStartT;
            _breakEndTime[i] = _breakEndT;
        }

    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getWorkTimesForAllEmployeesBetweenTwoDates(uint256 _startDate, uint256 _endDate) public view
        returns (
                 uint256[] memory _date,
                 address[][] memory _empAddress,
                 uint256[][] memory _startWork,
                 uint256[][] memory _endWork,
                 uint256[][] memory _breakStartTime,
                 uint256[][] memory _breakEndTime
                ) {

        require(_startDate < _endDate, "Start date must be less than end date.");
        require(_startDate >= pontoBlock.getCreationDateContract(), "Start date must be equals or grather than creationDate.");

        _date = new uint256[](_endDate - _startDate);
        _empAddress = new address[][](_endDate - _startDate);
        _startWork = new uint256[][](_endDate - _startDate);
        _endWork = new uint256[][](_endDate - _startDate);
        _breakStartTime = new uint256[][](_endDate - _startDate);
        _breakEndTime = new uint256[][](_endDate - _startDate);

        for (uint256 j = 0; j < _endDate - _startDate; j++) {
            for (uint256 i = _startDate; i <= _endDate; i++) {
                (_empAddress[j], _startWork[j], _endWork[j], _breakStartTime[j], _breakEndTime[j]) =
                    getWorkTimesForAllEmployeesAtDate(i);
                _date[j] = i;
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

}