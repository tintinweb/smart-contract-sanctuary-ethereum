/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// File: employee.sol

//SPDX-License-Identifier:Unlicenced
pragma solidity ^0.8.9;


contract employeedata {

    struct empDATA {
        string name;
        string salary;
        uint emp_id;
        string company;
    }

    empDATA[]  Employee;

    function addEmployee(uint emp_id, string memory name, string memory salary, string memory company) public {
		empDATA memory empdata = empDATA(name, salary,emp_id, company);
		Employee.push(empdata);
	}

    function getEmployeeByID(uint256 _id) public view returns(string memory name, string memory salary, string memory company){
        for (uint i = 0; Employee.length>i; i++){
            empDATA memory emp_data = Employee[i];
			if(emp_data.emp_id == _id){
				return(emp_data.name, emp_data.salary, emp_data.company);
			}
        }
    }

}