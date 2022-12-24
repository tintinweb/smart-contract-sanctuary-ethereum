/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <=0.8.0;

contract crowdFunding {

    //struct containing project attributes
    struct project {
        uint256 projectID;
        string projectTitle;
        string projectDescription;
        address payable projectOwner;
        uint256 projectParticipationAmount; //in wei
        uint256 projectTotalFundingAmount;
    }

    //A mapping which maintains individual contributions. ProjectID -> Contributor's addresss -> Amount
    mapping(uint256 => mapping(address => uint256)) contributions;
   
    //Dynamic Array holding list of projects
    project[] projects;

    //function to create / list a new project - returns newly created project ID
    function createProject(string memory _title, string memory _desc, uint256 _participationAmount) public returns ( uint256 ) {
        //_title should not be empty
        require(bytes(_title).length>0, "title cannot be empty.");
        //_desc should not be empty
        require(bytes(_desc).length>0, "description cannot be empty.");
        //minimum contribution must be greater than zero
        require(_participationAmount > 0, "Minimum contribution must be greater than zero");
        //create a project struct with supplied parameters and add it to projects array
        project memory newProject;
        newProject.projectID = projects.length; //project IDs will be from 0 to length-1
        newProject.projectTitle = _title;
        newProject.projectDescription = _desc;
        newProject.projectOwner= msg.sender;
        newProject.projectParticipationAmount = _participationAmount;
        projects.push(newProject);
        //return the succesfully created projectID
        return(newProject.projectID);
    }

    //function to fund a certain project
    function participateToProject(uint _projectID) payable public {
        //projectID must be between 0 and length-1
        require(_projectID >= 0 && _projectID < projects.length, "Invalid Project ID");
        //amount to contribute must be more than or equal to minimum contribution amount
        require(msg.value >= projects[_projectID].projectParticipationAmount,"Supplied amount is less than Project Participation Amount");
        //Increment the project's total funding with the supplied amount
        projects[_projectID].projectTotalFundingAmount += msg.value;
        //Increment the sender's contribution amount with the supplied amount
        contributions[_projectID][msg.sender] += msg.value;
    }

    //function to search for a project based on projectID
    function searchForProject(uint256 _projectID) public view returns (
        uint256 id,
        string memory title,
        string memory desc,
        address owner,
        uint256 participationAmount,
        uint256 totalFundingAmount)  {
        
        //projectID must be between 0 and length-1
        require(_projectID >= 0 && _projectID < projects.length, "Invalid Project ID");
        //return project details
        return(
            projects[_projectID].projectID,
            projects[_projectID].projectTitle,
            projects[_projectID].projectDescription,
            projects[_projectID].projectOwner,
            projects[_projectID].projectParticipationAmount,
            projects[_projectID].projectTotalFundingAmount
        );

    }

    //function to view all contribution made from specific ethereum address to a project
    function retrieveContributions(uint256 _projectID, address _contributor) public view returns(uint256){
        //projectID must be between 0 and length-1
        require(_projectID >= 0 && _projectID < projects.length, "Invalid Project ID");
        //retrieve the contribution
        return contributions[_projectID][_contributor];
    }

    //function to transfer current projectTotalFundingAmount of a project to owner's wallet.
    //Note: since the word "current" is used, its permitted to claim as many times as needed.
    //i.e, no explicit requirement of one-time-claim mentioned in the question.
    function withdrawFunds(uint256 _projectID) public {
        //projectID must be between 0 and length-1
        require(_projectID >= 0 && _projectID < projects.length, "Invalid Project ID");
        //get project details
        project memory currentProject = projects[_projectID];
        //check if the withdrawer is the owner of the project
        require(currentProject.projectOwner == msg.sender,"Only the project owner can withdraw");
        //transfer 'current' projectTotalFundingAmount to owner's wallet
        currentProject.projectOwner.transfer(currentProject.projectTotalFundingAmount);
        //reset total funding amount as zero
        currentProject.projectTotalFundingAmount=0;

    }

    //Utility functions

    //Function to retrieve current balance of the crowdfunding smart contract
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

}