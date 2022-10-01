/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract CrowdFund{

    uint256 public numberOfProjects = 0;
    mapping(uint256 => Project) projects;
    mapping(uint256 => uint256) public balances;
    // store amount user has donated
    mapping(address => mapping(uint256 => uint256)) public donationsPerUserPerProject;
    mapping(address => uint256) public usersTotalDonations;
    // donationsPerUserPerProject[msg.sender][0]; // get total donation for project by user

    event CreatedNewProject(uint256 id, string name);

    constructor() {}

    struct Project{
        uint256 id;
        string name;
        address organizer;
        address recipient;
        uint256 targetAmount;
        uint256 accumulatedAmount;
    }

    // by def. string are stored in state, memory says store in memory
    function createProject(string memory _name, address _recipient, uint256 _targetAmount) public {
        // check parms are valid
        require(_recipient != address(0), "Cannot be address zero");
        // create project object and set variables
        projects[numberOfProjects] = Project({
            id: numberOfProjects,
            name: _name,
            organizer: msg.sender,
            recipient: _recipient,
            targetAmount: _targetAmount,
            accumulatedAmount: 0
        });

        numberOfProjects++;
        // way of notifiying front-end
        emit CreatedNewProject(numberOfProjects - 1, _name);
    }

    // payable means the function can recieve funds
    function donate(uint256 _projectId) payable public {
        // check project id exists
        require(_projectId <= numberOfProjects, "Invalid ID");

        // record that project has recieved more cash
        projects[_projectId].accumulatedAmount += msg.value;
        balances[_projectId] += msg.value;
        // increase record of total user donations
        usersTotalDonations[msg.sender] += msg.value;
        // increase record of total user donation for this project
        donationsPerUserPerProject[msg.sender][_projectId] += msg.value;
        if(projects[_projectId].accumulatedAmount >= projects[_projectId].targetAmount){
            // call withdraw
            withdraw(_projectId);
        }
    }

    function withdraw(uint256 _projectId) internal {
        // dont need to check project id is valid because this function 
        // could only be called with project id existed
        
        // gas optimization
        Project memory tempProject = projects[_projectId];

        balances[_projectId] -= tempProject.accumulatedAmount;
        address targetRecipient = tempProject.recipient;
        uint256 amountPayable = tempProject.accumulatedAmount;

        (bool sent, ) = targetRecipient.call{value: amountPayable}("");
        require(sent, "Failed to send Ether");
    }

    // any smart contract that wants to recieve ether must have a receive function
    receive() external payable{}

    // store amount a user has donated


}