// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AdministratorContract.sol";

contract EmployeeContract {

    struct Employee {
        uint256 idEmployee;
        address employeeAddress;
        uint256 taxId;
        string name;
        State stateOf;
    }

    enum State { Inactive, Active }
    mapping (uint256 => Employee) private employees;
    address[] private addsEmployees;

    AdministratorContract private admin;

    constructor(address _adm) {
        admin = AdministratorContract(_adm);
    }

    // HANDLING EMPLOYEE //

    function addEmployee(address _address, string memory _name, uint256 _taxId) public{
        require(admin.checkIfAdministratorExists(msg.sender), "Sender is not administrator.");
        require(!checkIfEmployeeExists(_address), "Employee already exists.");
        require(_taxId != 0, "TaxId not given.");
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Name not given.");
        require(_address != address(0), "Address not given.");

        employees[addsEmployees.length] = Employee(addsEmployees.length, _address, _taxId, _name, State.Active);
        addsEmployees.push(_address);
    }

    function getEmployee(uint256 _id) public view returns(Employee memory) {
        return employees[_id];
    }

    function updateEmployee (address _address, uint256 _taxId, string memory _name, State _state) public {
        require(admin.checkIfAdministratorExists(msg.sender), "Sender is not administrator.");
        require(_address != address(0), "Address not given.");
        require(_taxId != 0, "TaxId not given.");
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Name not given.");
        require(checkIfEmployeeExists(_address), "Employee not exists.");

        bool difAdd;
        address add;
        uint256 _id;

        for (uint256 i = 0; i < addsEmployees.length; i++) {
            if (addsEmployees[i] ==  _address) {
                _id = i;
                break;
            }
        }

        if (employees[_id].employeeAddress != _address) {
            difAdd = true;
            add = employees[_id].employeeAddress;
        }

        employees[_id] = Employee(_id, _address, _taxId, _name, _state);

        if (difAdd) {
            for (uint256 i = 0; i < addsEmployees.length; i++) {
                if (addsEmployees[i] == add) {
                    addsEmployees[i] = _address;
                    break;
                }
            }
        }
    }

    function getAllEmployees() public view returns (Employee[] memory) {
        Employee[] memory result = new Employee[](addsEmployees.length);
        for (uint i = 0; i < addsEmployees.length; i++) {
            result[i] = employees[i];
        }
        return result;
    }

    function checkIfEmployeeExists(address _address) public view returns (bool){
        for (uint i = 0; i < addsEmployees.length; i++)
            if(addsEmployees[i] == _address)
                return true;

        return false;
    }

    // END HANDLING EMPLOYEE //
}