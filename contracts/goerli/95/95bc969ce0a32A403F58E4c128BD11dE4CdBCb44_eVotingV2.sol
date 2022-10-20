/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

//SPDX-License-Identifier: MIT

pragma solidity >= 0.8.14;

contract eVotingV2 {
    uint256 public deployTime;
    uint public proposalID = 0;
    address public owner;

    constructor() {
        deployTime = block.timestamp;
        owner = msg.sender;
    }

    struct Admin {
        string name;
        string position;
        bool isAdmin;
    }

    struct VoterStruct {
        string voterName;
        string position;
        bool isRegist;
    }

    struct Proposal {
        uint proposalIndex;
        string proposer;
        string title;
        uint256 startTime;
        uint256 endTime;
        string[] voteChoice;
        uint[] choiceCount;
        string[] voterAdd;
        string[] votedAdd; 
    }

    mapping(string => Admin) public adminAll;
    mapping(string => VoterStruct) public votersAll; // addvoters
    mapping (string => uint) proposalId;
    string[] public voterAccounts;
    string[] public voterName;
    Proposal[] public proposals;
    modifier onlyOwner {
      require(msg.sender == owner, "Only owner can call");
      _;
   }

    // show time 
    function showTime() public view returns(uint256){
            return block.timestamp;
        }
    
    function addAdmin(string calldata _name, string calldata _customerId, string calldata _position) public onlyOwner{
        adminAll[_customerId] = Admin({
            name: _name,
            position: _position,
            isAdmin: true
        });
    }

    function addVoter(string calldata _name, string calldata _customerId, string calldata _position) public {
        // require(adminAll[_customerId].isAdmin == true, "You are not admin");
        require(votersAll[_customerId].isRegist != true, "Already registed");
        votersAll[_customerId] = VoterStruct({
            voterName: _name,
            position: _position,
            isRegist: true
        });
        voterAccounts.push(_customerId);
        voterName.push(_name);
    }

    function createProposal(string calldata _title, uint256 _startTime, uint256 _durationInMin, string calldata _customerId, string[] calldata _choice ) public {
        uint256 _endTime = _startTime + _durationInMin*60;
        proposalId[_customerId] = proposalID;
        proposals.push(Proposal({
            proposalIndex: proposalID,
            proposer: _customerId,
            title: _title,
            startTime: _startTime,
            endTime: _endTime,
            voteChoice: _choice,
            choiceCount: new uint[](_choice.length),
            voterAdd: new string[](0),
            votedAdd: new string[](0)
        }));
        proposalID++;

    }

    //add choice
    function addChoice(uint _proposalIndex, string calldata _choice, string calldata _customerId) public {
        require(( keccak256(abi.encodePacked((_customerId))) == keccak256(abi.encodePacked((proposals[_proposalIndex].proposer)))), "You are not proposer");
        require(proposals[_proposalIndex].startTime > showTime(), "The proposal already opened can not add choice");
        proposals[_proposalIndex].voteChoice.push(_choice);
        proposals[_proposalIndex].choiceCount.push(0);
    }

    //add voters to each proposal
    function registToProposal(uint _proposalIndex, string calldata _customerId) public {
        require(votersAll[_customerId].isRegist = true, "Please regist");
        require(checkVoterInProposal(_customerId, _proposalIndex) == false, "Already regist");
        proposals[_proposalIndex].voterAdd.push(_customerId);
    }

    //vote
    function vote(uint _proposalIndex, uint _voteChoiceIndex, string calldata _customerId) public {
        require(votersAll[_customerId].isRegist = true, "Please regist");
        // require(msg.sender == _yourAddress, "Only can vote from your own address");
        require(showTime() <= proposals[_proposalIndex].endTime, "out of time");
        require(checkVoterInProposal(_customerId, _proposalIndex) == true, "Don't have right in this propersal, Please regist to the proposal");
        require(checkIsVoteInProposal(_customerId, _proposalIndex) == false, "Already voted");
        proposals[_proposalIndex].votedAdd.push(_customerId);
        proposals[_proposalIndex].choiceCount[_voteChoiceIndex] += 1;
    }

    //find winner
    function winningCandidateIndex(uint _proposalIndex) public view returns(uint winningCandidate) {
        uint winningVoteCount = 0;
        for(uint i = 0; i < proposals[_proposalIndex].choiceCount.length; i++){
            if(proposals[_proposalIndex].choiceCount[i] > winningVoteCount){
                winningVoteCount = proposals[_proposalIndex].choiceCount[i];
                winningCandidate = i;
            }
        }
        return winningCandidate;
    }

    //show winner
    function winningCandidateName(uint _proposalIndex) public view returns(string memory _winner) {
        _winner = proposals[_proposalIndex].voteChoice[winningCandidateIndex(_proposalIndex)];
        return _winner;
    }

    //check 
    function checkVoterInProposal(string calldata _customerId, uint _proposalIndex) public view returns(bool isRegist) {
        for(uint i = 0; i < proposals[_proposalIndex].voterAdd.length; i++){
            if( keccak256(abi.encodePacked((proposals[_proposalIndex].voterAdd[i]))) == keccak256(abi.encodePacked((_customerId)))){
                isRegist = true;
                return isRegist;
            }
        }
        isRegist = false;
        return isRegist;
    }

    function checkIsVoteInProposal(string calldata _customerId, uint _proposalIndex) public view returns(bool isVote) {
        for(uint i = 0; i < proposals[_proposalIndex].votedAdd.length; i++){
            if( keccak256(abi.encodePacked((proposals[_proposalIndex].votedAdd[i]))) == keccak256(abi.encodePacked((_customerId)))){
                isVote = true;
                return isVote;
            }
        }
        isVote = false;
        return isVote;
    }

    //returns
    function showAllVotersInProposal(uint _proposalIndex) public view returns(string[] memory){
        return proposals[_proposalIndex].voterAdd;
    }

    function showAllProposals() public view returns(Proposal[] memory){
        return proposals;
    }

    function showVoterInformation(string calldata _customerId)public view returns(VoterStruct memory){
        return votersAll[_customerId];
    }

    function showChoice(uint _proposalIndex)public view returns(string[] memory){
        return proposals[_proposalIndex].voteChoice;
    }

    function showChoiceCount(uint _proposalIndex)public view returns(uint[] memory){
        return proposals[_proposalIndex].choiceCount;
    }

    //new
    function showVoterRegistStatatus(string calldata _customerId)public view returns(bool){
        return votersAll[_customerId].isRegist;
    }

    function showProposalStartTime(uint _proposalIndex)public view returns(uint256){
        return proposals[_proposalIndex].startTime;
    }

    function showProposalEndTime(uint _proposalIndex)public view returns(uint256){
        return proposals[_proposalIndex].endTime;
    }

    function showProposer(uint _proposalIndex)public view returns(string memory){
        return proposals[_proposalIndex].proposer;
    }

    function showAllVotersName() public view returns(string[] memory){
        return voterName;
    }

    function showAllVotersCustomerId() public view returns(string[] memory){
        return voterAccounts;
    }

    function showAdminStatus(string calldata _customerId) public view returns(bool){
        return adminAll[_customerId].isAdmin;
    }

    function showProposalcount() public view returns(uint){
        return proposalID;
    }

    function showProposalId(string calldata _customerId)public view returns(uint){
        return proposalId[_customerId];
    }

    function showProposalTitle(uint _proposalIndex)public view returns(string memory){
        return proposals[_proposalIndex].title;
    }

    function showProposerName(uint _proposalIndex)public view returns(string memory){
        string memory customerId = proposals[_proposalIndex].proposer;
        return votersAll[customerId].voterName;
    }
}