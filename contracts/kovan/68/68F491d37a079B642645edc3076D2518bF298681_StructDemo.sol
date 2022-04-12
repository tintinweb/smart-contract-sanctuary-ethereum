/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.1;
contract StructDemo{
   struct Employee{
       uint256 id;
       string name;
       string department;
       string designation;
   }
   Employee[] emps;
       uint256 id=0;
    function addEmployee(string memory _name,string memory _department,string memory _designation) public {
      emps.push(Employee(id,_name,_department,_designation));
      id++;
    }
    function getEmployee(uint256 _id) public view returns(Employee memory){
       require(_id>=0);
       require(_id<id);
       return emps[_id];
    }

}