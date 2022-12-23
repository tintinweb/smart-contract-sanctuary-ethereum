/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Authen{

    struct Owner {
        address addr;
        string name;
        string surname;
        string grade;
    }

    mapping(address => Owner) user;
    event Data(address Address, string Name, string Surname, string Grade);

    //create data function
    function create(address _address,string memory _name, string memory _surname, string memory _grade) public {
        require(_address == msg.sender, "Unauthorized!");
        require(user[_address].addr != msg.sender,"Have Data in Blockchain Already!");
        user[_address].addr = _address;
        user[_address].name = _name;
        user[_address].surname = _surname;
        user[_address].grade = _grade;
        emit Data(msg.sender,_name,_surname,_grade);
    }

    //ReportData
    function reportData(address _address) public view returns(string memory name, string memory surname, string memory grade){
        require(_address == msg.sender,"Unauthorized");
        return (user[_address].name,user[_address].surname,user[_address].grade);
    }

}