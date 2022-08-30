//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract pvt_task {
// struct Task{
// string taskId;
// address[] taskEmployee;
// uint256 level;
// }
struct EmployeeData {
uint256 employeeIndex;
uint256 taskId;
address employeeAddress;
bool employeeStatus;
}

    EmployeeData[] public employeeData;

    address public i_owner;
    error NotOwner();
    // uint256 public taskId;
    // address[] public employeeAddress;
    mapping(address => bool) public addressToStatus;
    mapping(address => uint256) public addressToTask;
    //mpdifier
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert("Unauthorized");
        _;
    }
    modifier onlyParty() {
        address verifyEmployeeAddress;
        for (
            uint256 employeeIndex = 0;
            employeeIndex < employeeData.length;
            employeeIndex++
        ) {
            if (msg.sender == employeeData[employeeIndex].employeeAddress) {
                _;
            }
        }
        revert("Not authorized to Verify this task");
    }

    //constructor
    constructor() {
        i_owner = msg.sender;
    }

    function setEmployee(
        uint256 _employeeIndex,
        uint256 _taskId,
        address _employeeAddress,
        bool _employeeStatus
    ) public onlyOwner {
        employeeData.push(
            EmployeeData(
                _employeeIndex,
                _taskId,
                _employeeAddress,
                _employeeStatus
            )
        );
        addressToStatus[_employeeAddress] = _employeeStatus;
        addressToTask[_employeeAddress] = _taskId;
    }

    function setStatus(bool _taskStatus) public onlyParty {
        addressToStatus[msg.sender] = _taskStatus;
    }

    function getTaskId(address _employeeAddress) public view returns (uint256) {
        return addressToTask[_employeeAddress];
    }

    function getStatus(address _employeeAddress) public view returns (bool) {
        return addressToStatus[_employeeAddress];
    }

}