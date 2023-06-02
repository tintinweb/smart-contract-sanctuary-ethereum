/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract myFirstProject{
    string public name="saqib";
    string public courseName="blockChain";
    string public Duration="3months";
    uint public classNo=14;
    uint public age=23;
    function changeValue(string memory _name,string memory _courseName, string memory _duration,uint _classNo,uint _age) public{
          name=_name;
          courseName=_courseName;
          Duration=_duration;
          classNo=_classNo;
           age=_age;

    }
    function showStdRecord()public view returns(string memory _name,string memory _courseName, string memory _duration,uint _classNo,uint _age){
        return(name,courseName,Duration,classNo,age);
    }
}