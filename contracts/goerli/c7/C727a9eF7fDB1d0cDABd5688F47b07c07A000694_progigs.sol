// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract progigs {
    struct Project {
        address owner;
        string title;
        string description;
        uint256 budget;
        uint256 deadline;
        string image;
        address freelancer;
        string[] updates;
        bool isApproved;
        address[] proposals;
        bool status;
        mapping(address => Proposal) proposalMap;
    }

    struct Proposal {
        string description;
        uint256 amount;
        bool isAccepted;
    }

    mapping(uint256 => Project) public projects;
    uint256 public numberOfProjects = 0;

    function postProject(
        string memory _title,
        string memory _description,
        uint256 _budget,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        Project storage project = projects[numberOfProjects];
        project.owner = msg.sender;
        project.title = _title;
        project.description = _description;
        project.budget = _budget;
        project.deadline = _deadline;
        project.image = _image;
        project.isApproved = false;
        project.status = false;
        numberOfProjects++;
        return numberOfProjects - 1;
    }

    function postProposal(
        uint256 _projectId,
        string memory _description,
        uint256 _amount
    ) public {
        require(_projectId < numberOfProjects, "Invalid project ID");
        Project storage project = projects[_projectId];
        require(
            msg.sender != project.owner,
            "Owner cannot post proposal for their own project"
        );
        require(
            !project.isApproved,
            "Project is already approved, cannot post proposal"
        );

        Proposal storage proposal = project.proposalMap[msg.sender];
        require(!proposal.isAccepted, "Proposal is already accepted");

        proposal.description = _description;
        proposal.amount = _amount;
        project.proposals.push(msg.sender);
    }

    function approveProposal(
        uint256 _projectId,
        address _proposalOwner
    ) public payable {
        require(_projectId < numberOfProjects, "Invalid project ID");
        Project storage project = projects[_projectId];
        require(
            msg.sender == project.owner,
            "Only project owner can approve proposal"
        );

        Proposal storage proposal = project.proposalMap[_proposalOwner];
        project.freelancer = _proposalOwner;
        require(
            proposal.amount == msg.value,
            "Incorrect amount sent for proposal"
        );
        require(!proposal.isAccepted, "Proposal is already accepted");
        project.isApproved = true;
        proposal.isAccepted = true;
    }

    function rejectProposal(uint256 _projectId, address _proposalOwner) public {
        require(_projectId < numberOfProjects, "Invalid project ID");
        Project storage project = projects[_projectId];
        require(
            msg.sender == project.owner,
            "Only project owner can reject proposal"
        );

        Proposal storage proposal = project.proposalMap[_proposalOwner];
        require(!proposal.isAccepted, "Proposal is already accepted");

        delete project.proposalMap[_proposalOwner];
        for (uint i = 0; i < project.proposals.length; i++) {
            if (project.proposals[i] == _proposalOwner) {
                delete project.proposals[i];
                break;
            }
        }
    }

    function AcceptProject(uint256 _projectId) public payable {
        require(_projectId < numberOfProjects, "Invalid project ID");
        Project storage project = projects[_projectId];
        require(
            msg.sender == project.owner,
            "Only project owner can complete project"
        );
        require(
            project.isApproved,
            "Project must be approved before completion"
        );
        require(
            msg.value == project.budget,
            "Incorrect amount sent for project completion"
        );

        for (uint i = 0; i < project.proposals.length; i++) {
            Proposal storage proposal = project.proposalMap[
                project.proposals[i]
            ];
            if (proposal.isAccepted) {
                (bool sent, ) = payable(project.proposals[i]).call{
                    value: proposal.amount
                }("");
                require(sent, "Failed to send payment to proposalowner");
            }
        }
        project.status = true;
    }

    function addUpdate(uint256 _projectId, string memory _update) public {
        require(_projectId < numberOfProjects, "Invalid project ID");
        Project storage project = projects[_projectId];
        require(
            msg.sender == project.freelancer,
            "Only the assigned freelancer can add an update"
        );
        project.updates.push(_update);
    }

    function getUpdates(
        uint256 _projectId
    ) public view returns (string[] memory) {
        require(_projectId < numberOfProjects, "Invalid project ID");
        Project storage project = projects[_projectId];

        return project.updates;
    }
}