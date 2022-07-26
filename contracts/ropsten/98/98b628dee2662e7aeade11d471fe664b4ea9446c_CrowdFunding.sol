/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding {
    enum FundraisingState {
        Opened,
        Closed
    }

    struct Project {
        string id;
        string name;
        string description;
        address payable author;
        FundraisingState status;
        uint256 funds;
        uint256 fundraisingGoal;
    }

    struct Contribution {
        address contributor;
        uint256 value;
    }

    Project[] public projects;

    mapping(uint256 => Contribution[]) contributions;
    event ProjectFunded(string projectId, uint256 value);

    event ProjectStateChanged(string id, FundraisingState state);

    modifier isAuthor(uint256 projectId) {
        require(
            projects[projectId].author == msg.sender,
            "You need to be the project author"
        );
        _;
    }

    modifier isNotAuthor(uint256 projectId) {
        require(
            projects[projectId].author != msg.sender,
            "As author you can not fund your own project"
        );
        _;
    }

    function createProject(
        string memory _id,
        string memory _name,
        string memory _description,
        uint256 _fundraisingGoal
    ) public {
        require(
            _fundraisingGoal > 0,
            "fundraising goals must be greater than 0"
        );
        Project memory project = Project(
            _id,
            _name,
            _description,
            payable(msg.sender),
            FundraisingState.Opened,
            0,
            _fundraisingGoal
        );

        projects.push(project);
    }

    function fundProject(uint256 projectId)
        public
        payable
        isNotAuthor(projectId)
    {
        //I dunno if this is better but the instructor make all logic creating a memory's var and change this and then pushing to array of projects
        //Project memory actualProject = projects[projectId];
        require(
            projects[projectId].status != FundraisingState.Closed,
            "The project can not receive funds"
        );
        require(msg.value > 0, "Fund value must be greater than 0");
        projects[projectId].author.transfer(msg.value);
        projects[projectId].funds += msg.value;

        contributions[projectId].push(Contribution(msg.sender, msg.value));
        emit ProjectFunded(projects[projectId].id, msg.value);
    }

    function changeProjectState(uint256 projectId, FundraisingState newState)
        public
        isAuthor(projectId)
    {
        //Project memory actualProject = projects[projectId];
        require(
            projects[projectId].status != newState,
            "New state must be different"
        );
        projects[projectId].status = newState;
        emit ProjectStateChanged(projects[projectId].id, newState);
    }
}