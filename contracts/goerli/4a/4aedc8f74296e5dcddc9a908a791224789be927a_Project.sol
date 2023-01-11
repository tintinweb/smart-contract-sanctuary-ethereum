/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Project {

    mapping(uint256 => ProjectApproval) projectNumberToApproval;


    struct ProjectApproval {
        uint256 count;
        mapping(address => UserApproval) projectToUserApprovals;
    }   

    struct UserApproval {
        bool upVoted;
        string message;
    }

    function addUserApproval(uint256 projectNum, string memory message) public returns (bool success) {
        require(projectNumberToApproval[projectNum].projectToUserApprovals[msg.sender].upVoted == false, "User has already approved!");

        projectNumberToApproval[projectNum].projectToUserApprovals[msg.sender] = UserApproval(true, message);
        projectNumberToApproval[projectNum].count++;
        return true;
    }

    function getNumberOfProjectApproval(uint256 projectNum) public view returns (uint256 num) {
        return projectNumberToApproval[projectNum].count;
    }

    function getUserApprovalForProject(uint256 projectNum) public view returns (UserApproval memory) {
        return projectNumberToApproval[projectNum].projectToUserApprovals[msg.sender];
    }
}