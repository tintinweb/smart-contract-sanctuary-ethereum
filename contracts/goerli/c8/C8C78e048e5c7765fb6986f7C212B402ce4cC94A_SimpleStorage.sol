// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage
 {
    uint256  public favoriteNumber;
    People[] public people;
    mapping ( string => uint256) public personToNumber;
    mapping (uint256=> string) public numberToPerson;
    struct People {
        string name; 
        uint256 favoriteNumber;
    }
  
   //store of favorite numbers
    function  store(uint256 _favoriteNumber)public{
       favoriteNumber= _favoriteNumber;
    }
    
    //function retrieve the favorite number
    function retrieve() public view returns(uint256){
    return favoriteNumber;
    }

    //function to add a person with his favorite number in the list
    function addPerson(string memory _name, uint256 _favoriteNumber) public{
         people.push(People(_name, _favoriteNumber));
         //map each name to his favorite number
         personToNumber[_name]=_favoriteNumber;
         numberToPerson[_favoriteNumber]=_name;
    }
    
    
    
    //list of people with their favorite numbers


  
}