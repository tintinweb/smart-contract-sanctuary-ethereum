/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;


contract Student {
    uint private rollNo;
    string private name;


    /** @dev funtion setDetails take the _name and _rollNO of studen in augment
     *  _rollNo is saved in   rollNo
     *  _name is saved in name 
    */
    function setDetails(string memory _name,uint _rollNo) public{
     rollNo= _rollNo;
     name= _name;
     }

    /** @dev function getDetails is a view function 
     *  getdetails returns name and rollno of student
     */
    
    function getName () view public returns (string memory){
     return name;
     }
     
    function getRollNo () view public returns (uint){
     return rollNo;
     }

}