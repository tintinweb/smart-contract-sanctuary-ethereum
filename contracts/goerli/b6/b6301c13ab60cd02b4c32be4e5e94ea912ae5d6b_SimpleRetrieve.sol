/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract SimpleRetrieve { 


  string internal country;
  string internal name; 
  string internal city; 
  uint internal age;
  

  struct People {    
    string name;
    string country; 
    string city; 
    uint age;

  }


  // An array is a list, below is a dynamic array:
  People[] internal people; 

  mapping(string => string) public NameToCountry; 
  mapping(string => string) public NameToCity; 
  mapping(string => uint) public NameToAge;


function Register ( 
  string memory _name,
  string memory _country,
  string memory _city, 
  uint _age
  ) internal { 
    name = _name;
    country = _country; 
    city = _city; 
    age =_age; 


  }



function addPerson (string memory _name, string memory _country, string memory _city, uint _age) external  { 
  people.push(People(_name, _country, _city, _age)); 
  NameToCountry[_name]  = _country; 
  NameToCity[name] = _city; 
  NameToAge[_name] = _age; 

}

}