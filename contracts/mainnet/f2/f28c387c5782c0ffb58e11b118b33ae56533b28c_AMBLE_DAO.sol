/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

//SPDX-License-Identifier: UNLICENSED
// Copyright 2022 Mychael Henry (@mychael__henry)
pragma solidity ^0.8.8; 

// @title AMBLE DAO Membership 
// @author @mychael__henry

contract AMBLE_DAO {
mapping(string => uint256) public RollCall;
 
struct People {
    uint256 number; 
    string name;
    }

People[] public people;
        
function addPerson(string memory _name, uint256 _number) public {
people.push(People(_number, _name));
RollCall[_name] = _number;
    }
  
}