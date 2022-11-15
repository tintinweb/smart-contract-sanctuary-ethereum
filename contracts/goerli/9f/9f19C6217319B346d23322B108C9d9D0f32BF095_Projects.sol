pragma solidity ^0.8.7;
//SPDX-License-Identifier: UNLICENSED

contract Projects{
    
    uint private projectIndex = 0;
    //client - the one who created the project.
    //assignee - the freelancer
    struct Project {
        uint id;
        string projectTitle;
        string projectDescription;
        uint duration;
        address payable assignee;
        address payable client;
        uint creationTime;
        uint[] checkpointRewards;
        string[] checkpointNames;
        string[] checkpointLinks;
        mapping(uint => bool) checkpointsCompleted;
        mapping(address => uint) applicants;
        address[] applicantsList;
    }
    
    //Stores all project id's for getter function.
    uint[] private allProjects;


    //mapping from project id (created by backend) to Project struct. Stores all project details.
    mapping(uint => Project) private projects;                  
    
    
    //------------------EVENTS------------------
    event ProjectAdded(uint _id, address _clientAddress);
    event ProjectAssigned(uint _id, address _assigneeAddress);
    event CheckpointCompleted(uint _id, uint _checkpointIndex);
    event ProjectUnassigned(uint _id);
    event ProjectDeleted(uint _id);
    //------------------------------------------
    
    
    //------------------MODIFIERS------------------
    modifier onlyClient(uint _id) {
        require(msg.sender == projects[_id].client, "Only client can do this");
        _;
    }
    
    modifier onlyAssignee(uint _id) {
        require(msg.sender == projects[_id].assignee, "Only assignee can do this");
        _;
    }
    
    modifier onlyClientOrAssignee(uint _id) {
        require(msg.sender == projects[_id].client || msg.sender == projects[_id].assignee, "Only client or assignee can do this");
        _;
    }
    
    modifier projectExists(uint _id){
        require(projects[_id].id != 0, "Project does not exist");
        _;
    }
    
    modifier isAssigned(uint _id){
        require(projects[_id].assignee != address(0), "Project not yet assigned");
        _;
    }
    //---------------------------------------------
    
    
    //Add project. For Checkpoint only reward values as uint[] is passed. By default all checkpoints.completed == false.
    //In case client does not want to have a checkpoint based reward, a single checkpoint corresponding to 100% completion will be made (handled by stack application).
    function addProject(string calldata projectTitle, string calldata projectDescription, uint duration, string[] memory _checkpointNames, uint[] calldata _checkpointRewards) public returns(bool) {
        uint _id = projectIndex + 1;
        require(_checkpointRewards.length > 0, "Checkpoints required");
        require(projects[_id].id == 0, "Project already added");
        
        projects[_id].id = _id;
        projects[_id].projectTitle = projectTitle;
        projects[_id].projectDescription = projectDescription;
        projects[_id].duration = duration;
        projects[_id].client = payable(msg.sender);
        projects[_id].creationTime = block.timestamp;
        projects[_id].checkpointRewards = _checkpointRewards;
        projects[_id].checkpointNames = _checkpointNames;
        projects[_id].checkpointLinks = new string[](_checkpointRewards.length);

        allProjects.push(_id);
        projectIndex++;

        emit ProjectAdded(_id, msg.sender);
        return true;
    }
    
    //Assign project. Client will also have to transfer value to smart contract at this point.
    function assign(uint _id, address payable assigneeAddress) public projectExists(_id) onlyClient(_id) payable returns(bool) {
        require(projects[_id].assignee == address(0), "Project already assigned");
        require(assigneeAddress != address(0), "Zero address submitted");
        
        uint totalReward;
        for(uint i=0; i<projects[_id].checkpointRewards.length; i++){
            if(!projects[_id].checkpointsCompleted[i]){
                totalReward += projects[_id].checkpointRewards[i];
            }
        }

        if(msg.value < totalReward){
            revert("Insufficient funds");
        }
        
        projects[_id].assignee = assigneeAddress;
        
        emit ProjectAssigned(_id, assigneeAddress);
        return true;
    }
    
    //Set checkpoint link if checkpoint is not completed. If checkpoint is completed, link cannot be changed. Only assignee can do this.
    function setCheckpointLink(uint _id, uint _checkpointIndex, string calldata _link) public projectExists(_id) isAssigned(_id) onlyAssignee(_id) returns(bool) {
        require(_checkpointIndex < projects[_id].checkpointLinks.length, "Invalid checkpoint index");
        require(!projects[_id].checkpointsCompleted[_checkpointIndex], "Checkpoint already completed");
        
        projects[_id].checkpointLinks[_checkpointIndex] = _link;
        return true;
    }

    //Verify checkpoint. Only client can do this.
    function verifyCheckpoint(uint _id, uint _checkpointIndex) public projectExists(_id) isAssigned(_id) onlyClient(_id) returns(bool) {
        require(_checkpointIndex < projects[_id].checkpointLinks.length, "Invalid checkpoint index");
        require(!projects[_id].checkpointsCompleted[_checkpointIndex], "Checkpoint already completed");
        
        projects[_id].checkpointsCompleted[_checkpointIndex] = true;
        emit CheckpointCompleted(_id, _checkpointIndex);
        return true;
    }

    //Apply for a project, if not already applied. Client cannot apply.
    function applyForProject(uint _id) public projectExists(_id) returns(bool) {
        require(msg.sender != projects[_id].client, "Client cannot apply");
        require(projects[_id].applicants[msg.sender] == 0, "Already applied");
        
        projects[_id].applicantsList.push(msg.sender);
        projects[_id].applicants[msg.sender] = projects[_id].applicantsList.length;
        return true;
    }

    function cancelApplyForProject(uint _id) public projectExists(_id) returns(bool) {
        require(msg.sender != projects[_id].client, "Client cannot cancel application");
        require(projects[_id].applicants[msg.sender] != 0, "No previous application found");
        
        uint index = projects[_id].applicants[msg.sender];
        projects[_id].applicants[msg.sender] = 0;
        delete projects[_id].applicantsList[index-1];
        return true;
    }

    //mark checkpoint as completed and transfer reward
    function checkpointCompleted(uint _id, uint index) public projectExists(_id) onlyClient(_id) isAssigned(_id) returns(bool) {
        require(index < projects[_id].checkpointRewards.length, "Checkpoint index out of bounds");
        require(!projects[_id].checkpointsCompleted[index], "Checkpoint already completed");
        
        projects[_id].checkpointsCompleted[index] = true;
        
        emit CheckpointCompleted(_id, index);
        projects[_id].assignee.transfer(projects[_id].checkpointRewards[index]);
        
        return true;
    }
    
    //Called by client or assignee to unassign assignee from the project
    function unassign(uint _id) public projectExists(_id) isAssigned(_id) onlyClientOrAssignee(_id) returns(bool) {
        delete projects[_id].assignee;
        
        emit ProjectUnassigned(_id);
        uint totalReward;
        for(uint i=0; i<projects[_id].checkpointRewards.length; i++){
            if(!projects[_id].checkpointsCompleted[i]){
                totalReward += projects[_id].checkpointRewards[i];
            }
        }
    
        projects[_id].client.transfer(totalReward);
        return true;
    }
    
    //delete project. Requires unassigning first so that remainingReward is not lost.
    function deleteProject(uint _id) public projectExists(_id) onlyClient(_id) returns(bool) {
        if (projects[_id].assignee != address(0))
            unassign(_id);
        
        delete allProjects[projects[_id].id - 1];
        delete projects[_id];
        
        emit ProjectDeleted(_id);
        return true;
    }
    
    
    //------------------GETTERS------------------
    function getAllProjects() public view returns(uint[] memory) {
        return allProjects;
    }
    
    function getProject(uint _id) public view projectExists(_id) returns(address, address, string memory, string memory,uint) {
        bool[] memory _tempCheckpoints = new bool[](projects[_id].checkpointRewards.length);

        for(uint i=0; i<projects[_id].checkpointRewards.length; i++){
            _tempCheckpoints[i] = projects[_id].checkpointsCompleted[i];
        }
        
        return (
            projects[_id].client,
            projects[_id].assignee,
            projects[_id].projectTitle,
            projects[_id].projectDescription,
            projects[_id].creationTime
        );
    }

    function getProjectApplicants(uint _id) public view projectExists(_id) returns(address[] memory) {
        return projects[_id].applicantsList;
    }

    function getCheckpointRewardsDetails(uint _id) public view projectExists(_id) returns(string[] memory, uint[] memory, bool[] memory, string[] memory) {
        bool[] memory _tempCheckpoints = new bool[](projects[_id].checkpointRewards.length);

        for(uint i=0; i<projects[_id].checkpointRewards.length; i++){
            _tempCheckpoints[i] = projects[_id].checkpointsCompleted[i];
        }

        return (
            projects[_id].checkpointNames,
            projects[_id].checkpointRewards,
            _tempCheckpoints,
            projects[_id].checkpointLinks
        );
    }
    
    function getAssigneeProjects(address _assigneeAddress) view public returns(uint[] memory) {
        require(_assigneeAddress != address(0), "Zero address passed");
        uint[] memory _tempProjects = new uint[](allProjects.length);
        uint counter;
        for(uint i = 0; i<allProjects.length; i++){
            if(projects[allProjects[i]].assignee == _assigneeAddress){
                _tempProjects[counter] = allProjects[i];
                counter++;
            }
        }
        uint[] memory _projects = new uint[](counter);
        for(uint i=0; i<counter; i++){
            _projects[i] = _tempProjects[i];
        }
        return _projects;
    }
    
    function getClientProjects(address _clientAddress) public view returns(uint[] memory) {
        require(_clientAddress != address(0), "Zero address passed");
        uint[] memory _tempProjects = new uint[](allProjects.length);
        uint counter;
        for(uint i = 0; i<allProjects.length; i++){
            if(projects[allProjects[i]].client == _clientAddress){
                _tempProjects[counter] = allProjects[i];
                counter++;
            }
        }
        uint[] memory _projects = new uint[](counter);
        for(uint i=0; i<counter; i++){
            _projects[i] = _tempProjects[i];
        }
        return _projects;
    }
    //-------------------------------------------
   
}