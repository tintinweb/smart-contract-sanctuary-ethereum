/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-29
*/

pragma solidity 0.6.11;
//SPDX-License-Identifier: UNLICENSED

contract LancerSquare {
    
    //project desciption will be stored in a db, only its hash is stored here for proving that desciption has not been changed.
    //client - the one who created the project.
    //assignee - the freelancer
    struct Project {
        bytes20 projectHash;    //sha1
        address payable assignee;
        address payable client;
        uint allProjectsIndex;
        uint creationTime;
        uint[] checkpointRewards;
        mapping(uint => bool) checkpointsCompleted;
    }
    
    bytes12[] allProjects;                                  //Stores all project id's for getter function.
    mapping(bytes12 => Project) projects;                  //mapping from project id (created by backend) to Project struct. Stores all project details.
    
    
    //------------------EVENTS------------------
    event ProjectAdded(bytes12 _id, address _clientAddress);
    event ProjectAssigned(bytes12 _id, address _assigneeAddress);
    event CheckpointCompleted(bytes12 _id, uint _checkpointIndex);
    event ProjectUnassigned(bytes12 _id);
    event ProjectDeleted(bytes12 _id);
    //------------------------------------------
    
    
    //------------------MODIFIERS------------------
    modifier onlyClient(bytes12 _id) {
        require(msg.sender == projects[_id].client, "Only client can do this");
        _;
    }
    
    modifier onlyAssignee(bytes12 _id) {
        require(msg.sender == projects[_id].assignee, "Only assignee can do this");
        _;
    }
    
    modifier onlyClientOrAssignee(bytes12 _id) {
        require(msg.sender == projects[_id].client || msg.sender == projects[_id].assignee, "Only client or assignee can do this");
        _;
    }
    
    modifier projectExists(bytes12 _id){
        require(projects[_id].projectHash != 0, "Project does not exist");
        _;
    }
    
    modifier isAssigned(bytes12 _id){
        require(projects[_id].assignee != address(0), "Project not yet assigned");
        _;
    }
    //---------------------------------------------
    
    
    //Add project. For Checkpoint only reward values as uint[] is passed. By default all checkpoints.completed == false.
    //In case client does not want to have a checkpoint based reward, a single checkpoint corresponding to 100% completion will be made (handled by stack appliaction).
    function addProject(bytes12 _id, bytes20 _projectHash, uint[] calldata _checkpointRewards) external returns(bool) {
        require(_checkpointRewards.length > 0, "Checkpoints required");
        require(projects[_id].projectHash == 0, "Project already added");
        
        projects[_id].checkpointRewards = _checkpointRewards;
        projects[_id].client = msg.sender;
        projects[_id].projectHash = _projectHash;
        projects[_id].creationTime = block.timestamp;
        
        projects[_id].allProjectsIndex = allProjects.length;
        allProjects.push(_id);
        
        emit ProjectAdded(_id, msg.sender);
        return true;
    }
    
    //Assign project. Client will also have to transfer value to smart contract at this point.
    function assign(bytes12 _id, address payable assigneeAddress) projectExists(_id) onlyClient(_id) payable external returns(bool) {
        require(projects[_id].assignee == address(0), "Project already assigned");
        require(assigneeAddress != address(0), "Zero address submitted");
        
        uint totalReward;
        for(uint i=0; i<projects[_id].checkpointRewards.length; i++){
            if(!projects[_id].checkpointsCompleted[i]){
                totalReward += projects[_id].checkpointRewards[i];
            }
        }
        
        require(msg.value == totalReward, "Wrong amount submitted");
        
        projects[_id].assignee = assigneeAddress;
        
        emit ProjectAssigned(_id, assigneeAddress);
        return true;
    }
    
    //mark checkpoint as completed and transfer reward
    function checkpointCompleted(bytes12 _id, uint index) projectExists(_id) onlyClient(_id) isAssigned(_id) external returns(bool) {
        require(index < projects[_id].checkpointRewards.length, "Checkpoint index out of bounds");
        require(!projects[_id].checkpointsCompleted[index], "Checkpoint already completed");
        
        projects[_id].checkpointsCompleted[index] = true;
        
        emit CheckpointCompleted(_id, index);
        projects[_id].assignee.transfer(projects[_id].checkpointRewards[index]);
        
        return true;
    }
    
    //Called by client or assignee to unassign assignee from the project
    function unassign(bytes12 _id) projectExists(_id) isAssigned(_id) onlyClientOrAssignee(_id) public returns(bool) {
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
    function deleteProject(bytes12 _id) projectExists(_id) onlyClient(_id) external returns(bool) {
        if (projects[_id].assignee != address(0))
            unassign(_id);
        
        delete allProjects[projects[_id].allProjectsIndex];
        delete projects[_id];
        
        emit ProjectDeleted(_id);
        return true;
    }
    
    
    //------------------GETTERS------------------
    function getAllProjects() view public returns(bytes12[] memory) {
        return allProjects;
    }
    
    function get20Projects(uint _from) view public returns(bytes12[20] memory, uint) {
        bytes12[20] memory tempProjects;
        uint count = 0;
        uint i = allProjects.length-1 - _from;
        for(i; i >= 0 && count < 20; i--){
            if(allProjects[i] != 0) {
                tempProjects[count] = allProjects[i];
                count++;
            }
        } 
        return (tempProjects, allProjects.length-1-i);
    }
    
    function getProject(bytes12 _id) view public projectExists(_id) returns(address, address, bytes20, uint[] memory, bool[] memory, uint) {
        bool[] memory _tempCheckpoints = new bool[](projects[_id].checkpointRewards.length);
        for(uint i=0; i<projects[_id].checkpointRewards.length; i++){
            _tempCheckpoints[i] = projects[_id].checkpointsCompleted[i];
        }
        return (
            projects[_id].client,
            projects[_id].assignee,
            projects[_id].projectHash,
            projects[_id].checkpointRewards,
            _tempCheckpoints,
            projects[_id].creationTime
        );
    }
    
    function getAssigneeProjects(address _assigneeAddress) view public returns(bytes12[] memory) {
        require(_assigneeAddress != address(0), "Zero address passed");
        bytes12[] memory _tempProjects = new bytes12[](allProjects.length);
        uint counter;
        for(uint i = 0; i<allProjects.length; i++){
            if(projects[allProjects[i]].assignee == _assigneeAddress){
                _tempProjects[counter] = allProjects[i];
                counter++;
            }
        }
        bytes12[] memory _projects = new bytes12[](counter);
        for(uint i=0; i<counter; i++){
            _projects[i] = _tempProjects[i];
        }
        return _projects;
    }
    
    function getClientProjects(address _clientAddress) view public returns(bytes12[] memory) {
        require(_clientAddress != address(0), "Zero address passed");
        bytes12[] memory _tempProjects = new bytes12[](allProjects.length);
        uint counter;
        for(uint i = 0; i<allProjects.length; i++){
            if(projects[allProjects[i]].client == _clientAddress){
                _tempProjects[counter] = allProjects[i];
                counter++;
            }
        }
        bytes12[] memory _projects = new bytes12[](counter);
        for(uint i=0; i<counter; i++){
            _projects[i] = _tempProjects[i];
        }
        return _projects;
    }
    //-------------------------------------------
   
}