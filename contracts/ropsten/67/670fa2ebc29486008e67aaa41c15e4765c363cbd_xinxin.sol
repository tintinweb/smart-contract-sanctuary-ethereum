/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

pragma solidity ^0.5.1;

contract xinxin {
   person[] public people;

   uint256 public peoplecount;

   struct person{
       string _firstname;
       string _lastname;
   }

   function addPerson123(string memory _firstname, string memory _lastname) public{
       people.push(person(_firstname,_lastname));
       peoplecount += 1 ;
   }
}