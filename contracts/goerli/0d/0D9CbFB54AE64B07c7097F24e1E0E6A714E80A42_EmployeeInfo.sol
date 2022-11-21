/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmployeeInfo{

// Structure of employee
struct Employee{
	
	// State variables
	uint empid;
	string name;
	string department;
	string designation;
    uint salary;
}

Employee []emps;

// Function to add employee details
function addEmployee(
	uint empid, string memory name,
	string memory department,
	string memory designation,
    uint salary
) public{
	Employee memory e = Employee(empid,
                                name,
                                department,
                                designation,
                                salary);
	emps.push(e);
}

// Function to get details of employee
function getEmployee(
	uint empid
) public view returns(
	string memory,
	string memory,
	string memory,
    uint){
	uint i;
	for(i=0;i<emps.length;i++)
	{
		Employee memory e = emps[i];
		
		// Looks for a matching employee id
		if(e.empid==empid)
		{
				return(e.name,
					e.department,
					e.designation,
                    e.salary);
		}
	}
	
	// If provided employee id is not present it returns Not found
	return ("Not Found",
            "Not found",
            "Not found",
             0);
}

function getSalary(uint empid) public view returns(string memory,uint) {
    	uint i;
	for(i=0;i<emps.length;i++)
	{
		Employee memory e = emps[i];
		
		// Looks for a matching employee id
		if(e.empid==empid)
		{
				if(e.salary>= 1000) {
                    return("Salary is greater than 1000",e.salary);
                }
                else {
                    return("Salary less than 1000",e.salary);
            }
		}
	}
}
}