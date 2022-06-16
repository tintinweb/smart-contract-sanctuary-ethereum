/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0<0.9.0;

contract Personal_Info{

struct Info{
    string  name;
    string email;
    string phone;
    string hash;
}

Info[] Persons;
uint256 no_of_people;

constructor(){
    no_of_people=0;
}

function Add_Person(string memory _name,string memory _email,string memory _phone,string memory _hash) public {
    Persons.push(Info(_name,_email,_phone,_hash));
    no_of_people++;
}

function Get_Info(uint256 id) public view returns(string memory,string memory,string memory,string memory){
    return (Persons[id].name,Persons[id].email,Persons[id].phone,Persons[id].hash);

}

function getName(uint256 _id) public view returns(string memory)
{
return Persons[_id].name;
}


function getEmail(uint256 _id) public view returns(string memory)
{
return Persons[_id].email;
}

function getPhone(uint256 _id) public view returns(string memory)
{
return Persons[_id].phone;
}

function getHash(uint256 _id) public view returns(string memory)
{
return Persons[_id].hash;
}
}