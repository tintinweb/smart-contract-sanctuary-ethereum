/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
contract Student{
    mapping(uint=>string) public studentData;
    mapping(uint=>bool) public exists;
    event NewEnroll(uint roll,string name);
    function enroll(uint _roll,string memory _name) public{
            require(exists[_roll]==false,"Student already enrolled");
            require(bytes(_name).length>0,"Name field can't be empty");
            exists[_roll]=true;
            studentData[_roll]=_name;
            emit NewEnroll(_roll,_name);
     }
}