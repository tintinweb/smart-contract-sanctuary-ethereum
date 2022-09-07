/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Employees{

    struct Person{
        uint Salary;
        string name;
    }

    struct Emp{
        uint code;
        uint Salary;
        string name;
    }

    uint public  total_emp;

    Person public emp1;

    mapping (uint => Person) private Emp_detail;

    Emp[] public empDetail;

    function name(string memory _name,uint _salary) external {
        emp1.name = _name;
        emp1.Salary = _salary;
    }

    function enterDetails(uint _code,string memory _name,uint _salary) external {
        Person memory temp;
        temp.name =_name;
        temp.Salary=_salary;
        Emp_detail[_code]=temp;


        // Emp_detail[_code].name = _name;
        // Emp_detail[_code].Salary = _salary;



        // Person storage temp = Emp_detail[_code];
        // temp.name = _name;
        // temp.Salary = _salary;


Emp memory temp1;
temp1.name = _name;
temp1.code =_code;
temp1.Salary =_salary;

empDetail.push(temp1);

    }

    function enterStruct(uint _code , Person memory _user) external {
        Emp_detail[_code] = _user;
    }

    function readData(uint _code) public view returns (Person memory){
        return Emp_detail[_code] ;
        }


        function readLength() view public returns (uint){
            return empDetail.length;
        }

}