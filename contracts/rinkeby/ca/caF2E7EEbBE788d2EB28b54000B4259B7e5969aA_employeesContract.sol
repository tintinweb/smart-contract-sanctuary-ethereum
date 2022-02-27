//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract employeesContract {
    uint256 employeeId;
    struct employee {
        string Name;
        uint256 ethSalary;
        uint256 totalYearlyHoursWorked;
    }

    mapping(address => employee) addressToEmployee;

    function addNewEmployee(
        address _newAddress,
        string memory _name,
        uint256 _ethSalary,
        uint256 _totalYearlyHoursWorked
    ) public {
        addressToEmployee[_newAddress] = employee(
            _name,
            _ethSalary,
            _totalYearlyHoursWorked
        );
    }

    function sendEmployeeMonthlyPaycheckETH(address _employeeAddress)
        public
        payable
    {
        uint256 monthlyValue = addressToEmployee[_employeeAddress].ethSalary /
            12;
        payable(address(_employeeAddress)).transfer(monthlyValue);
    }
}