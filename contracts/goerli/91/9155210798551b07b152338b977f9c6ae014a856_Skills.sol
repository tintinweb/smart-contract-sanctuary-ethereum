/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Skills{

    event event_skills(string name,string proficiency);

    address public owner;
    
    constructor(){
        owner=msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Only the owner can send message.");
        _;
    }

    struct struct_skills{
        string name;
        string proficiency;
    }

    struct_skills[] public skills;

    function setSkills(string memory _s1,string memory _s2) public onlyOwner{
         struct_skills memory skillset=struct_skills({name:_s1,proficiency:_s2});
         skills.push(skillset);
         emit event_skills(_s1,_s2);
    }
}