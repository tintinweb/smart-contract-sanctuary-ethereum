/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
// File: contracts/Beginner.sol


pragma solidity ^0.8.15;

contract Beginner {

// this gets initialized to one!
// <- this means that this section is a comment!
uint256 public Onenumber;

mapping (string => uint256) public nametoOnenumber;

struct people {
    uint256 Onenumber;
    string name;
    

}
    people[] public People;

function store (uint256 _Onenumber) public {
    Onenumber = _Onenumber;
    
    }
     // view, pure
    function retrieve () public view returns (uint256){
       return Onenumber;
    }
      // calldata, memory, storage
    function addPeople (string memory _name, uint256 _Onenumber) public{
        People.push(people(_Onenumber, _name));
        nametoOnenumber[_name] = _Onenumber;
    }
}