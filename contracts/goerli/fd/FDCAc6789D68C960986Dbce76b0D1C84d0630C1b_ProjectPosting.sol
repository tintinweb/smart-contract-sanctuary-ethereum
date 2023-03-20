// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ProjectPosting {

    struct Project {
        string name;
        string datasetFeatures;
        string datasetNature;
        address client;
        uint deadline;
        uint offer;
        bool isOpen;
        address[] freelancer;
    }

    mapping (uint => Project) public projects;
    uint public projectsCount = 0;

    event ProjectPosted(uint projectId, string name, string datasetFeatures, string datasetNature, address client);

    event ProjectEdited(uint projectId, string name, string datasetFeatures, string datasetNature, uint deadline, uint offer);

    event ProjectPicked(uint projectId, address[] freelancer);

    function postProject(string memory _name, string memory _datasetFeatures, string memory _datasetNature, uint _deadline, uint _offer) public returns (uint){
        Project storage project = projects[projectsCount];

        // require(project.deadline > block.timestamp, "The deadline should be a date in the future");

        project.name = _name;
        project.datasetFeatures = _datasetFeatures;
        project.datasetNature = _datasetNature;
        project.client = msg.sender;
        project.deadline = _deadline;
        project.offer = _offer;
        project.isOpen = true;

        projectsCount++;

        emit ProjectPosted(projectsCount, _name, _datasetFeatures, _datasetNature, msg.sender);

        return projectsCount - 1;
    }

    function editProject(uint _projectId, string memory _name, string memory _datasetFeatures, string memory _datasetNature, uint _deadline, uint _offer) public {
        require(_projectId < projectsCount, "Project with this ID does not exist");

        Project storage project = projects[_projectId];

        // Ensure only the project creator can edit the project
        require(project.client == msg.sender, "Only project creator can edit the project");

        project.name = _name;
        project.datasetFeatures = _datasetFeatures;
        project.datasetNature = _datasetNature;
        project.deadline = _deadline;
        project.offer = _offer;

        emit ProjectEdited(_projectId, _name, _datasetFeatures, _datasetNature, _deadline, _offer);

    }

    function closeProject(uint _projectId) public {
        require(projects[_projectId].client == msg.sender, "Only the client who posted the project can close it.");
        projects[_projectId].isOpen = false;
    }

    function pickProject(uint _projectId) public{
        require(projects[_projectId].isOpen, "The project should be in open state");

        Project storage project = projects[_projectId];

        project.freelancer.push(msg.sender);

        emit ProjectPicked(_projectId, project.freelancer);

    }

    function getFreelancers(uint _project_id) view public returns (address[] memory){
        return projects[_project_id].freelancer;
    }

}