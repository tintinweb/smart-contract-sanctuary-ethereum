/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract mappingSample 
{

    mapping (uint8 => learner) learners;
    struct learner 
    {
        string name;
        uint8 age;
    }
 
    function setLearnerDetails(uint8 _key, string memory _name, uint8 _age) public 
    {     
     learners[_key].name=_name;
     learners[_key].age=_age;
    }

    function getLearnerDetails(uint8 _key) public view returns (string memory, uint8)
    {
     
     return (learners[_key].name, learners[_key].age);
    }
}