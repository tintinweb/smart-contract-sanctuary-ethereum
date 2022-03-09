/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Mapping {

    mapping(uint => string) userNames;
    mapping(uint => uint) userAges;


    function setUserNameAge(uint id, string memory name, uint Age) public {
        userNames[id] = name;
        userAges[id] = Age;
       
    }

    function getUserDetails(uint id) public view returns (string memory, uint){
        return (userNames[id], userAges[id]);
        
    }



   
}