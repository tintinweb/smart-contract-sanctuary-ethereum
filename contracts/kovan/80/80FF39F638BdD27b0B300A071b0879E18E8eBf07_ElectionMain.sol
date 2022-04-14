// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract ElectionMain{
    address[] approvedElections;
    address[] pendingElections;
    address gctcAddress;
    uint256 requiredGCTCamountToCreateTopic;
    uint256 requiredGCTCamountToVote;
    uint256[] stringLimit = [32,1000,32];
    address public owner;
    uint public totalTopics;

    constructor(address _gctcAddress, uint256 _requiredGCTCamountToCreateTopic, uint256 _requiredGCTCamountToVote) {
        owner= msg.sender;
        gctcAddress = _gctcAddress;
        requiredGCTCamountToCreateTopic = _requiredGCTCamountToCreateTopic;
        requiredGCTCamountToVote = _requiredGCTCamountToVote;
    }

    mapping(address => bool) public moderators;
    mapping(address => uint256) public ids;
    mapping(address => bool) hasApproved;
    mapping(address => bool) valid;

    modifier onlyOwner{
        require(owner== msg.sender ,"Only owner can do this.");
        _;
    }
    
    function createElection(string memory title, string memory description, string memory category) public {
        require(IERC20(gctcAddress).balanceOf(msg.sender) >= requiredGCTCamountToCreateTopic,"Not enough token to create election.");
        require(bytes(title).length> 0,"Require Valid title.");
        require(bytes(description).length> 0,"Require Valid description");
        require(bytes(title).length<= stringLimit[0],"expect less char for title");
        require(bytes(description).length<= stringLimit[1],"expect less char for description");
        require(bytes(category).length<= stringLimit[2],"expect less char for category");

        address cont = address(new Election(msg.sender, title, description, category, gctcAddress, requiredGCTCamountToVote));
        
        ++totalTopics;
        ids[cont] = totalTopics; 
        pendingElections.push(cont);
        valid[cont] = true;
    }

    function approveTopic(address _topicAddress,uint256 _id) public{
        require(valid[_topicAddress],"Not Valid Address");
        require(!hasApproved[_topicAddress],"Already Approved");
        require(moderators[msg.sender], "You need to be Moderator");
        delete pendingElections[_id-1];
        approvedElections.push(_topicAddress);
        hasApproved[_topicAddress] = true;
    } 

    function addModerator(address _addModerator) public onlyOwner{
        moderators[_addModerator] = true;
    }   

    function addManyModerator(address[] memory _addModerators) public onlyOwner {
        for (uint256 i = 0; i < _addModerators.length; i++) {
        moderators[_addModerators[i]] = true;
    }
    }

    function removeModerator(address _removeModerator) public onlyOwner{
        moderators[_removeModerator] = false;
    } 

    function verifyModerators(address _moderatorAddress) public view returns (bool) {
        bool userIsModerator = moderators[_moderatorAddress];
        return userIsModerator;
    }    

    function setRequiredGCTCamountToCreateTopic(uint256 _requiredGCTCamountToCreateTopic) public onlyOwner{
        requiredGCTCamountToCreateTopic = _requiredGCTCamountToCreateTopic;
    }   

    function setRequiredGCTCamountToVote(uint256 _requiredGCTCamountToVote) public onlyOwner{
        requiredGCTCamountToVote = _requiredGCTCamountToVote;
    }

    function getApprovedElections() public view returns (address[] memory) {
        return approvedElections;
    }

    function getPendingElections() public view returns (address[] memory) {
        return pendingElections;
    }

    function setStringLimit(uint256 titleStringLimit,uint256 descriptionStringLimit,uint256 categoryStringLimit) public onlyOwner {
        stringLimit[0] = titleStringLimit;
        stringLimit[1] = descriptionStringLimit;
        stringLimit[2] = categoryStringLimit;
    }

    function getStringLimit() public view returns (uint256[] memory) {
        return stringLimit;
    }

}

contract Election {
    address public ORGANIZER;
    string[] public options;
    
    mapping(string => uint) totalVotes;
    mapping(address => bool) hasVoted;
    
    bool public votingStatus = false;
    string public description;
    string public title;
    string public category;
    address gctcAddress;
    uint256 requiredGCTCamountToVote;
    string winner;

    constructor(address _org, string memory _title, string memory _description, string memory _category, address _gctcAddress, uint256 _requiredGCTCamountToVote) {
        title = _title;
        description = _description;
        category = _category;
        ORGANIZER = _org;
        gctcAddress = _gctcAddress;
        requiredGCTCamountToVote = _requiredGCTCamountToVote;
        options = ["Accept","Reject"];
        for(uint i = 0; i<options.length; i++){
            totalVotes[options[i]] = 0;
        }
        winner = "";
        votingStatus = true;
    }
    
    function vote(uint i) public {
        require(votingStatus,"Voting is ended.");
        require(!hasVoted[msg.sender],"Already did a vote.");
        require(IERC20(gctcAddress).balanceOf(msg.sender) >= requiredGCTCamountToVote,"Not enough token to vote."); 

        hasVoted[msg.sender] = true;
        totalVotes[options[i]]++;
    }
    
    function endVoting() public{
        require(votingStatus);
        require(msg.sender == ORGANIZER);
            if(totalVotes[options[0]] > totalVotes[options[1]]){
                winner = options[0];
            }else if (totalVotes[options[0]] < totalVotes[options[1]]){
                winner = options[1];
            }else{
                winner = "neutral";   
            }
        votingStatus = false;
        ORGANIZER = address(0);
    }
    
    function votesCount() public view returns (uint256[2] memory, uint256){
        uint256[2] memory count;
        uint256 total;
        count = [totalVotes[options[0]],totalVotes[options[1]]];
        total = count[0]+count[1];
        return (count,total);
    }   

    function result() public view returns (string memory){
        require(!votingStatus);
        return winner;
    }

    function giveOptionsList() public view returns (string[] memory) {
        return options;
    }
}