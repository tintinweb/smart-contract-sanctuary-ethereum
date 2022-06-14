/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage{
   uint256 fav;

  mapping (string=>uint256) public nametoFav;

//declare class and class variables
   struct People{ 
       uint256 favi;
       string name;
   }
   //create array of objects
   People[] public people;
   
   function addPerson(string memory _name, uint256 newfav) public {
       //add to array
       people.push(People(newfav,_name));
       nametoFav[_name]=newfav;
   }

   function store(uint256 newfav) public {
       fav = newfav;
   }

   function getfav() public view returns(uint){
       return fav;
   }
   
    
}