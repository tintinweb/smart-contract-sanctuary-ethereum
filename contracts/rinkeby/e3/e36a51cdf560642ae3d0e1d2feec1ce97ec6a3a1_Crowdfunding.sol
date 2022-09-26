//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './Project.sol';

contract Crowdfunding{

// [X] Anyone can start a funding project .
// [X] Get All project list
// [X]  contribute amount

event ProjectStarted(
    address projectContractAddress ,
    address creator,
    uint256 minContribution,
    uint256 projectDeadline,
    uint256 goalAmount,
    uint256 currentAmount,
    uint256 noOfContributors,
    string title,
    string desc,
    uint256 currentState
);

event ContributionReceived(
   address projectAddress,
   uint256 contributedAmount,
   address indexed contributor
);

 Project[] private projects;

  // @dev Anyone can start a fund rising
 // @return null

 function createProject(
    uint256 minimumContribution,
    uint256 deadline,
    uint256 targetContribution,
    string memory projectTitle,
    string memory projectDesc
 ) public {

   deadline = deadline;

   Project newProject = new Project(msg.sender,minimumContribution,deadline,targetContribution,projectTitle,projectDesc);
   projects.push(newProject);
 
 emit ProjectStarted(
    address(newProject) ,
    msg.sender,
    minimumContribution,
    deadline,
    targetContribution,
    0,
    0,
    projectTitle,
    projectDesc,
    0
 );

 }

 // @dev Get projects list
// @return array

function returnAllProjects() external view returns(Project[] memory){
   return projects;
}

// @dev User can contribute
// @return null

function contribute(address _projectAddress) public payable{

   uint256 minContributionAmount = Project(_projectAddress).minimumContribution();
   Project.State projectState = Project(_projectAddress).state();
   require(projectState == Project.State.Fundraising,'Invalid state');
   require(msg.value >= minContributionAmount,'Contribution amount is too low !');
   // Call function
   Project(_projectAddress).contribute{value:msg.value}(msg.sender);
   // Trigger event 
   emit ContributionReceived(_projectAddress,msg.value,msg.sender);
}

}