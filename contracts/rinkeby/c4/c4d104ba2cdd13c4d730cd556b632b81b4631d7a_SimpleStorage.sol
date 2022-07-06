/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: MIT
//Makes sharing code easier
pragma solidity 0.8.8; // ^0.8.7; Any compiler above version 0.8.7 will work

contract SimpleStorage { //contract similar to class
   
   uint256 favouriteNumber; //initialized to 0 its a global variable
  People [] public people;//dynamic array: size not defined
  //function to add people to array
  mapping(string => uint256) public nameToFavouriteNumber; //mapping names to a number
  function addPerson(string memory _name, uint256 _favouriteNumber) public{
      People memory newPerson = People({favouriteNumber: _favouriteNumber, name: _name});
      people.push(newPerson);
      nameToFavouriteNumber[_name] = _favouriteNumber;
  }
  struct People { //ARRAY OF PEOPLE
        uint256 favouriteNumber;  
        string name; 
    } 
    function store (uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber; 
    }
    //view, pure dont modify state of fn
    function retrieve() public view returns(uint256){
           return favouriteNumber;
        }


}