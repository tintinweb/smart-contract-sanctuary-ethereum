/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.6.0 < 0.9.0;

contract VibhuSkillsTest {

    struct Skill {
        string name;
        uint256 level;
    }

    Skill[] public skillsData;
    mapping(string => uint256) public levels;
    
    function view_number_of_skills() public view returns (uint256){
        return skillsData.length;
    }

    function addSkill(string memory _skillName, uint256 _skillLevel) public {
        skillsData.push(Skill(_skillName, _skillLevel));
        levels[_skillName] = _skillLevel;
    }
}