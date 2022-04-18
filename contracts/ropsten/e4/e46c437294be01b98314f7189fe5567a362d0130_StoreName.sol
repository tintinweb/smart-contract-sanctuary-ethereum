/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//created by Daris Mathew aka RivalX

contract StoreName{
    string Sname;
    function NamePassed(string memory _x) public {
       Sname = _x; 
    }
    function Showname() public view returns(string memory){
      return Sname;
    }
}