/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// - Add new employees with the following data: id, fullname, gender, email      DONE
// - Update employee information                                                 DONE
// - Track an employee's check-in and check-out time                             DONE      
// - Review an employee's data                                                   DONE
// - Track how many times an employee was absent for work                        DONE

contract EmployeeContract {
    struct Employee {
        uint id;
        string fullname;
        string gender;
        string email;
    }

    struct TrackEmployee {
        uint id;
        string inTime;
        string outTime;
        uint absent;
    }

    address owner;
    mapping(uint => Employee) employees;

    mapping (uint=> TrackEmployee) track;
    
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "You're not the owner");
        _;

    }
    //Add new employee
    function addEmployee(string memory fullname, uint id, string memory gender, string memory email) public onlyOwner {
        employees[id] = Employee({
            id: id, 
            fullname: fullname, 
            gender: gender, 
            email: email
            });
    }
    
    //Update employee information
    function updateEmployee(uint id, string memory newfullname, string memory newgender, string memory newemail) public onlyOwner {
        Employee memory newemployee = employees[id];    
        newemployee.fullname = newfullname;
        newemployee.gender = newgender;
        newemployee.email = newemail;                  
        employees[id] = newemployee;         
    }

    //Review Employee's Data
    function get_employee_details(uint id) view public returns (Employee memory) {
        Employee memory empDetails = employees[id];
        return empDetails;
    }

    //Add Check-in, check-out, absent of employee
    function setEmpTrack(uint id, string memory inTime, string memory outTime, uint absent) public onlyOwner {
       track[id]= TrackEmployee({
            id: id,
            inTime: inTime,
            outTime: outTime,
            absent: absent
        });

    }
    
    //Track employee's check-in, check-out, and absent from work
    function get_employee_track(uint id) public view returns (TrackEmployee memory) {
        TrackEmployee memory empTrack = track[id];
        return empTrack;
    }
    
}