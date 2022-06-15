/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

pragma solidity 0.8.14;
//SPDX-License-Identifier: MIT
contract LancerSquare {
    //project desciption will be stored in a db, only its hash is stored here for proving that desciption has not been changed.
    //client - the one who created the project.
    //assignee - the freelancer
    struct Project {
        uint allProjectsIndex;
        uint clientProjectsIndex;
        uint assigneeProjectsIndex;
        uint assigneeOffersIndex;
        address payable client;
        address payable assignee;
        address payable offeredAssignee;
        string projectHash;
        uint remainingReward;
        uint[] checkpointRewards;
        bool[] checkpointsCompleted;
        uint creationTime;
        ProposedChange proposedChanges;
    }
    
    //Clients can propose changes to the project details but performing those changes will require approval from assignee too.
    //This struct stores the proposal
    struct ProposedChange{
        string newProjectHash;
        uint newRemainingReward;
        uint[] checkpointRewards;
        bool[] checkpointsCompleted;
    }
    
    mapping (bytes12 => Project) projects;                  //mapping from project id (created by backend) to Project struct. Stores all project details.
    bytes12[] allProjects;                                  //Stores all project id's for getter function.
    mapping(address => bytes12[]) assigneeProjects;         //Stores all project id's assigned to a user for getter function.
    mapping(address => bytes12[]) assigneeOffers;           //Stores all project id's offered to a user for getter function.
    mapping(address => bytes12[]) clientProjects;           //Stores all project id's created by a client for getter function.
    
    
    //------------------EVENTS------------------
    event ProjectAdded(bytes12 _id, address _clientAddress, string projectHash);
    
    event ProjectOffered(bytes12 _id, address _assigneeAddress);
    event OfferRejected(bytes12 _id);
    event ProjectAssigned(bytes12 _id);
    
    event CheckpointCompleted(bytes12 _id, uint _checkpointIndex);
    event ProjectUnassigned(bytes12 _id);
    event ProjectDeleted(bytes12 _id);
    
    event ProposalCreated(bytes12 _id, string hash);
    event ProposalAccepted(bytes12 _id);
    event ProposalRejected(bytes12 _id);
    //------------------------------------------
    
    
    //------------------MODIFIERS------------------
    modifier onlyClient(bytes12 _id) {
        require(msg.sender == projects[_id].client, "Only client is allowed to do this");
        _;
    }
    
    modifier onlyAssignee(bytes12 _id) {
        require(msg.sender == projects[_id].assignee, "Only assignee can do this");
        _;
    }
        
    modifier onlyClientOrAssignee(bytes12 _id) {
        require(msg.sender == projects[_id].client || msg.sender == projects[_id].assignee, "Only client and assignee are allowed to do this");
        _;
    }
    
    modifier onlyClientOrOfferedAssignee(bytes12 _id) {
        require(msg.sender == projects[_id].client || msg.sender == projects[_id].offeredAssignee, "Only client and offered assignee are allowed to do this");
        _;
    }
    
    modifier onlyOfferedAssignee(bytes12 _id) {
        require(msg.sender == projects[_id].offeredAssignee, "Only offered assignee can do this");
        _;
    }
    
    modifier projectExists(bytes12 _id){
        require(bytes(projects[_id].projectHash).length > 0, "Project does not exist");
        _;
    }
    
    modifier isAssigned(bytes12 _id){
        require(projects[_id].assignee != address(0), "Project not yet assigned");
        _;
    }
    
    modifier proposalExists(bytes12 _id){
        require(bytes(projects[_id].proposedChanges.newProjectHash).length > 0, "Proposal does not exist");
        _;
    }
    
    //When a change is propsed and not yet approved or rejected by the assignee or deleted by the client, the project "pauses".
    //This is for better money management because making and accepting/rejecting proposals also include value transfers.
    modifier proposalDoesNotExist(bytes12 _id){
        require(bytes(projects[_id].proposedChanges.newProjectHash).length == 0, "Proposal pending review exists");
        _;
    }
    //---------------------------------------------
    
    
    //Add project. For Checkpoint only reward values as uint[] is passed. By default all checkpoints.completed == false.
    //In case client does not want to have a checkpoint based reward, a single checkpoint corresponding to 100% completion will be made (handled by stack appliaction).
    function addProject(bytes12 _id, string memory _projectHash, uint[] memory _checkpointRewards) public returns(bool) {
        require(_id.length > 0, "id required");
        require(bytes(_projectHash).length > 0, "Project Hash required");
        require(_checkpointRewards.length > 0, "Checkpoints required");
        require(bytes(projects[_id].projectHash).length == 0, "Project already added");
        
        projects[_id].checkpointRewards = _checkpointRewards;
        uint totalReward = 0;
        for (uint i=0; i<_checkpointRewards.length; i++) {
            projects[_id].checkpointsCompleted.push(false);
            totalReward += _checkpointRewards[i];
        }
        projects[_id].remainingReward = totalReward;
        projects[_id].client = payable(msg.sender);
        projects[_id].projectHash = _projectHash;
        projects[_id].creationTime = block.timestamp;
        
        projects[_id].allProjectsIndex = allProjects.length;
        projects[_id].clientProjectsIndex = clientProjects[msg.sender].length;
        allProjects.push(_id);
        clientProjects[msg.sender].push(_id);
        
        emit ProjectAdded(_id, msg.sender, _projectHash);
        return true;
    }
    
    //Offer project. Client will also have to transfer value to smart contract at this point.
    function offer(bytes12 _id, address payable assigneeAddress) projectExists(_id) onlyClient(_id) payable public returns(bool) {
        require(projects[_id].assignee == address(0), "Project already assigned");
        require(assigneeAddress != address(0), "Zero address submitted");
        require(projects[_id].offeredAssignee == address(0), "Project already offered");
        require(msg.value == projects[_id].remainingReward, "Wrong amount submitted");
        
        projects[_id].offeredAssignee = assigneeAddress;
        
        projects[_id].assigneeOffersIndex = assigneeOffers[assigneeAddress].length;
        assigneeOffers[assigneeAddress].push(_id);
        
        emit ProjectOffered(_id, assigneeAddress);
        return true;
    }
    
    //accept offer. 
    function acceptOffer(bytes12 _id) projectExists(_id) onlyOfferedAssignee(_id) public returns(bool) {
        projects[_id].assignee = payable(msg.sender);
    
        projects[_id].assigneeProjectsIndex = assigneeProjects[msg.sender].length;
        assigneeProjects[msg.sender].push(_id);
        
        deleteOffer(_id);
        emit ProjectAssigned(_id);
        return true;
    }
    
    //Revoke offer. Cline or assignee can revoke a made offer and submitted amount is returned to the client.
    function revokeOffer(bytes12 _id) projectExists(_id) onlyClientOrOfferedAssignee(_id) public returns(bool) {
        require(projects[_id].assignee == address(0), "Project already assigned");
        require(projects[_id].offeredAssignee != address(0), "Project not yet offered");

        deleteOffer(_id);
        
        emit OfferRejected(_id);
        projects[_id].client.transfer(projects[_id].remainingReward);
        
        return true;
    }
    
    function deleteOffer(bytes12 _id) projectExists(_id) internal {
        bytes12[] storage tempAssigneeOffers = assigneeOffers[projects[_id].offeredAssignee];
        bytes12 lastAssigneeOfferId = tempAssigneeOffers[tempAssigneeOffers.length - 1];
        if (lastAssigneeOfferId != _id) {
            uint thisAssigneeOffersIndex = projects[_id].assigneeOffersIndex;
            tempAssigneeOffers[thisAssigneeOffersIndex] = lastAssigneeOfferId;
            projects[lastAssigneeOfferId].assigneeOffersIndex = thisAssigneeOffersIndex;
        }
        delete projects[_id].assigneeOffersIndex;
        delete projects[_id].offeredAssignee;
        tempAssigneeOffers.pop();
    }
    
    //mark checkpoint as completed and transfer reward
    function checkpointCompleted(bytes12 _id, uint index) projectExists(_id) onlyClient(_id) isAssigned(_id) proposalDoesNotExist(_id) public returns(bool) {
        require(index < projects[_id].checkpointsCompleted.length, "Checkpoint index out of bounds");
        require(!projects[_id].checkpointsCompleted[index], "Checkpoint already completed");
        
        projects[_id].checkpointsCompleted[index] = true;
        projects[_id].remainingReward -= projects[_id].checkpointRewards[index];
        
        emit CheckpointCompleted(_id, index);
        projects[_id].assignee.transfer(projects[_id].checkpointRewards[index]);
        
        return true;
    }
    
    //Called by client or assignee to unassign assignee from the project
    function unassign(bytes12 _id) projectExists(_id) isAssigned(_id) onlyClientOrAssignee(_id) public returns(bool) {
        
        bytes12[] storage tempAssigneeProjects = assigneeProjects[projects[_id].assignee];
        bytes12 lastAssigneeProjectId = tempAssigneeProjects[tempAssigneeProjects.length - 1];
        if (lastAssigneeProjectId != _id) {
            uint thisAssigneeProjectsIndex = projects[_id].assigneeProjectsIndex;
            tempAssigneeProjects[thisAssigneeProjectsIndex] = lastAssigneeProjectId;
            projects[lastAssigneeProjectId].assigneeProjectsIndex = thisAssigneeProjectsIndex;
        }
        delete projects[_id].assigneeProjectsIndex;
        delete projects[_id].assignee;
        tempAssigneeProjects.pop();
        
        emit ProjectUnassigned(_id);
        if(projects[_id].remainingReward > 0)
            projects[_id].client.transfer(projects[_id].remainingReward);
            
        return true;
    }
    
    //delete project
    function deleteProject(bytes12 _id) projectExists(_id) onlyClient(_id) proposalDoesNotExist(_id) public returns(bool) {
        if (projects[_id].assignee != address(0))
            unassign(_id);
        if (projects[_id].offeredAssignee != address(0))
            revokeOffer(_id);
        
        delete allProjects[projects[_id].allProjectsIndex];
        bytes12[] storage tempClientProjects = clientProjects[projects[_id].client];
        bytes12 lastClientProjectId = tempClientProjects[tempClientProjects.length - 1];
        if (lastClientProjectId != _id) {
            uint thisClientProjectsIndex = projects[_id].clientProjectsIndex;
            tempClientProjects[thisClientProjectsIndex] = lastClientProjectId;
            projects[lastClientProjectId].clientProjectsIndex = thisClientProjectsIndex;
        }
        delete projects[_id];
        tempClientProjects.pop();
        
        emit ProjectDeleted(_id);
        return true;
    }
    
    
    //------------------GETTERS------------------
    function getAllProjects() view public returns(bytes12[] memory) {
        return allProjects;
    }
    
    function get20Projects(uint _from) view public returns(bytes12[20] memory) {
        bytes12[20] memory tempProjects;
        for(uint i = 0; i < 20 && i < allProjects.length - _from; i++)
            tempProjects[i] = allProjects[_from + i];
        return tempProjects;
    }
    
    function getProject(bytes12 _id) view public projectExists(_id) returns(address, address, string memory, uint[] memory, bool[] memory, uint) {
        return (
            projects[_id].client,
            projects[_id].assignee,
            projects[_id].projectHash,
            projects[_id].checkpointRewards,
            projects[_id].checkpointsCompleted,
            projects[_id].creationTime
        );
    }
    
    function getOffers() view public returns(bytes12[] memory) {
        return assigneeOffers[msg.sender];
    }

    function getAssigneeProjects() view public returns(bytes12[] memory) {
        return assigneeProjects[msg.sender];
    }
    
    function getAssigneeProjects(address _assigneeAddress) view public returns(bytes12[] memory) {
        require(_assigneeAddress != address(0), "Zero address passed");
        return assigneeProjects[_assigneeAddress];
    }
    
    function getClientProjects() view public returns(bytes12[] memory) {
        return clientProjects[msg.sender];
    }
    
    function getClientProjects(address _clientAddress) view public returns(bytes12[] memory) {
        require(_clientAddress != address(0), "Zero address passed");
        return clientProjects[_clientAddress];
    }
    
    function getProposal(bytes12 _id) projectExists(_id) proposalExists(_id) view public returns(string memory, uint, uint[] memory, bool[] memory) {
        return (
            projects[_id].proposedChanges.newProjectHash,
            projects[_id].proposedChanges.newRemainingReward,
            projects[_id].proposedChanges.checkpointRewards,
            projects[_id].proposedChanges.checkpointsCompleted
        );
    }
    //-------------------------------------------
    
    
    //------------------CHANGING------------------
    //Creates a proposal for changing project details. If unassigned, the changes are done in this step only.
    //If assigned, then proposal is stored in the proposedChanges mapping.
    //If assigned and if reward is increased, the change in reward must be paid by client here only.
    //If assigned and if reward is decreased, the change will be paid back to client when proposal is accepted by the assignee.
    //At a time, only a single proposal can exists for a project.
    function createProposal(bytes12 _id, uint[] memory _checkpointRewards, bool[] memory _checkpointsCompleted, string memory _newProjectHash) projectExists(_id) onlyClient(_id) proposalDoesNotExist(_id) payable public returns(bool) {
        require(bytes(_newProjectHash).length > 0, "Project Hash required");
        require(_checkpointRewards.length > 0, "Checkpoints required");
        require(_checkpointRewards.length == _checkpointsCompleted.length, "Array lengths do not match");
        
        uint newAmountToBePaid = 0;
        for (uint i = 0; i<_checkpointRewards.length; i++)
            if(!_checkpointsCompleted[i])
                newAmountToBePaid += _checkpointRewards[i];
                
        if (projects[_id].assignee == address(0) && projects[_id].offeredAssignee == address(0))
            require(msg.value == 0, "Project is unassigned/unoffered, amount should be submitted when project is assigned/offered");
        else {
            if(newAmountToBePaid - projects[_id].remainingReward > 0)
                require(msg.value == newAmountToBePaid - projects[_id].remainingReward, "Wrong amount submitted");
            else
                require(msg.value == 0, "No increase in remaining reward. Amount submission not allowed");
        }
            
        if (projects[_id].assignee == address(0)) {
            projects[_id].checkpointRewards = _checkpointRewards;
            projects[_id].checkpointsCompleted = _checkpointsCompleted;
            projects[_id].projectHash = _newProjectHash;
            projects[_id].remainingReward = newAmountToBePaid;
        }
        else {
            projects[_id].proposedChanges.checkpointRewards = _checkpointRewards;
            projects[_id].proposedChanges.checkpointsCompleted = _checkpointsCompleted;
            projects[_id].proposedChanges.newProjectHash = _newProjectHash;
            projects[_id].proposedChanges.newRemainingReward = newAmountToBePaid;
        }
        
        emit ProposalCreated(_id, _newProjectHash);
        return true;
    }
    
    //Delete proposal to be called when client wants to take back the proposal.
    //Automatic calls to this method before executing methods like deleteContract() can be handled in stack application.
    function deleteProposal(bytes12 _id) projectExists(_id) onlyClient(_id) proposalExists(_id) public returns(bool) {
        return rejectChanges(_id);
    }
    
    //reject changes and return the extra money submitted by client in case an increase in reward was proposed.
    function rejectChanges(bytes12 _id) projectExists(_id) proposalExists(_id) internal returns(bool) {
        delete projects[_id].proposedChanges;
        emit ProposalRejected(_id);
        
        if (projects[_id].proposedChanges.newRemainingReward > projects[_id].remainingReward)
            projects[_id].client.transfer(projects[_id].proposedChanges.newRemainingReward - projects[_id].remainingReward);
            
        return true;
    }
    
    //accept or reject the changes
    //If accepted, transfer extra money back to client in case reward was decreased.
    //If rejected, call rejectChanges
    function assigneeResponse(bytes12 _id, bool response) projectExists(_id) onlyAssignee(_id) proposalExists(_id) public returns(bool) {
        if(response) {
            
            projects[_id].projectHash = projects[_id].proposedChanges.newProjectHash;
            projects[_id].checkpointRewards = projects[_id].proposedChanges.checkpointRewards;
            projects[_id].checkpointsCompleted = projects[_id].proposedChanges.checkpointsCompleted;
            projects[_id].remainingReward = projects[_id].proposedChanges.newRemainingReward;
            
            delete projects[_id].proposedChanges;
            emit ProposalAccepted(_id);
            
            if (projects[_id].remainingReward > projects[_id].proposedChanges.newRemainingReward)
                projects[_id].client.transfer(projects[_id].remainingReward - projects[_id].proposedChanges.newRemainingReward);
            
            return true;
        }
        else
            return rejectChanges(_id);
    }
    
}