/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract testContract {
    //basic struct for project info
    struct Project {
        int id;
        string name;
        string description;
        address beneficiary;
        uint goalAmt;
        uint endTime;
        bool claimed; //intialized to false by default, set to true once transferOut function is called successfully

        mapping(address => uint256) addToDonation;
        address[] donors;
    }

    //struct used for data retrieval
    struct publicData {
        int id;
        string name;
        string description;
        address beneficiary;
        uint goalAmt;
        uint256 currentAmt;
        uint timeLeft; //in seconds, convert to d/h/m/s in frontend. Returns zero if time has already passed
        bool claimed;
    }

    mapping(uint => Project) private projectList;
    uint[] idList;
    uint nextId; //also used for counting number of projects

    mapping(address => uint256) emptyMapping;
    address[] emptyDonorsList;

    constructor() {
        nextId = 0;
    }

    function createNewProject(
        string memory _name,
        string memory _description,
        address _beneficiary,
        uint _goalAmt, //keep this in wei
        uint _duration //in seconds
    ) public {
        idList.push(nextId);

        projectList[nextId].name = _name;
        projectList[nextId].description = _description;
        projectList[nextId].beneficiary = _beneficiary;
        projectList[nextId].goalAmt = _goalAmt * (10**18); //convert to wei
        projectList[nextId].endTime = block.timestamp + (_duration * 1 seconds);

        nextId += 1;
    }

    function donate(uint _id) public payable {
        require(block.timestamp < projectList[_id].endTime, "Fundraising must not have ended.");
        require(projectList[_id].claimed == false, "Funds from fundraising must not have been claimed.");

        projectList[_id].addToDonation[msg.sender] += msg.value; //msg.value is in wei
        if (newDonor(_id, msg.sender)) {
            projectList[_id].donors.push(msg.sender);
        }
    }

    //paysout beneficiary and resets all values of mapping to zero
    function transferOut(uint _id) public {
        require(msg.sender == projectList[_id].beneficiary, "Transfer out must only be done by beneficiary.");
        require(canWithdraw(_id), "Either goal must be met or fundraising must have ended.");
        projectList[_id].claimed = true;
        payable(projectList[_id].beneficiary).transfer(getTotalAmount(_id));
    }

    function canWithdraw(uint _id) private view returns (bool) {
        return ((block.timestamp > projectList[_id].endTime) || (getTotalAmount(_id) >= projectList[_id].goalAmt)) && !projectList[_id].claimed;
    }

    function getTotalAmount(uint _id) private view returns (uint256) {
        uint256 totalAmt = 0;
        for (uint i = 0; i < projectList[_id].donors.length; i++) {
            address temp = projectList[_id].donors[i];
            require(projectList[_id].addToDonation[temp] > 0);
            totalAmt += projectList[_id].addToDonation[temp];
        }
        return totalAmt;
    }

    //returns a tuple for all details regarding a project
    function getProjectDetails(uint _id) public view returns (publicData memory) {
        require(_id < nextId, "id queried must be an existing or expired project, cannot be out of index bounds");
        return publicData (
        {
        id: projectList[_id].id,
        name: projectList[_id].name,
        description: projectList[_id].description,
        beneficiary: projectList[_id].beneficiary,
        goalAmt: projectList[_id].goalAmt,
        currentAmt: getTotalAmount(_id),
        timeLeft: (projectList[_id].endTime > block.timestamp) ? (projectList[_id].endTime - block.timestamp) : 0,
        claimed: projectList[_id].claimed
        }
        );
    }

    //use the return value as upper limit of a loop for getting details of all projects
    function getLastUsedProjectId() public view returns (int) {
        if (nextId == 0) {
            return -1;
        }
        return int(nextId) - 1;
    }

    //checks if this is a new donor, so that a specific address can donate more than once to the same project
    function newDonor(uint _id, address _donor) private view returns (bool) {
        for (uint i = 0; i < projectList[_id].donors.length; i++) {
            if (projectList[_id].donors[i] == _donor) {
                return false;
            }
        }
        return true;
    }
}