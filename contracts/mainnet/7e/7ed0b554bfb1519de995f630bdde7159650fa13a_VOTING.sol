/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
abstract contract IUNIART {
    function companyAmount() public pure returns (uint){
        return 0;
    }

    struct executeVotingInfo
    {
        bool art;
        address recipient;
        uint256 amount;
    }
    
    executeVotingInfo private evi;

    function executeVoting(bool art, address recipient, uint amount) public {
        evi.art = art;
        evi.recipient = recipient;
        evi.amount = amount;
    }
}

abstract contract IERC223 {

    function balanceOf(address account) public pure returns (uint256){
        account;
        return 0;
    }

}

contract VOTING {
    event Vote(ActionType actionType, uint proposalIndex, address addr, uint8 vote);
    event FinishVoting(ActionType actionType, bool result, uint proposalIndex);
    event ProposalCreated(uint endTime, ActionType actionType, address actionAddress, uint8[] percents, address[] addresses, uint amount, uint proposalIndex);
    
    enum ActionType {add_voter, remove_voter, set_percent, eth_emission, art_emission_single, eth_emission_single}

    struct VoteStatus {
        address participant;
        uint8 vote; // 0 no 1 yes 2 resignation
    }
    
    struct Proposal {
        uint endTime;
        uint8 result; // 0 no 1 yes 2 notFinished
        ActionType actionType; // 0 add participant 1 remove participant 2 set percent 3 emision ETH 4 transfer ART 5 transfer ETH
        address actionAddress; // Add/Remove participant or transfer address
        uint8[] percents;
        address[] addresses;
        uint amount; // amount of transfered Wei
        address[] voters;
        uint8[] votes;
    }

    struct ParticipantVote {
        address addr;
        uint8 vote;
    }
    
    address uni;
    address erc223;
    address[] public participants;
    mapping(address => uint8) participantPercent;
    Proposal[] proposals;
    VoteStatus[] status;
    
    constructor(address one, address two) {
        participants.push(one);
        participants.push(two);
        participantPercent[one] = 50;
        participantPercent[two] = 50;
    }

    function registerUniART(address _uni, address _erc223) public {
        if(uni == address(0)){
            uni = _uni;
            erc223 = _erc223;
        }
    }

     function beforeCreateProposal(ActionType _actionType, address _actionAddress, uint8[] memory _percents, address[] memory _addresses, address _senderAddress, uint _amount) public view returns(bool, string memory) {

        if(findParticipantIndex(_senderAddress) == 0)
            return(true, "You are not in participant");
            
        if(uint(_actionType) < 2) {
            uint index = findParticipantIndex(_actionAddress);
            if(_actionType == ActionType.add_voter && index != 0)
                return(true, "This participant already exist");
            if(_actionType == ActionType.remove_voter){
                if(participantPercent[_actionAddress] > 0)
                    return(true, "The participant to delete must have zero percent");
                if(index == 0)
                    return(true, "This is not participant address");
                if(participants.length <= 2)
                    return(true, "Minimal count of participants is 2");
            }
        }
        if(_actionType == ActionType.set_percent){
            if(_percents.length != participants.length)
                return(true, "Wrong percents length");
            if(_addresses.length != participants.length)
                return(true, "Wrong addresses length");
            uint8 total = 0;
            for(uint i = 0; _percents.length > i; i++){
                total += _percents[i];
            }
            if(total != 100)
                return(true, "The sum of the percentages must be 100");
        }
        if(_actionType == ActionType.eth_emission || _actionType == ActionType.art_emission_single || _actionType == ActionType.eth_emission_single){
            if((_actionType == ActionType.art_emission_single || _actionType == ActionType.eth_emission_single) && _actionAddress == address(0))
                return(true, "Action address is empty");
            if(_amount == 0)
                return(true, "Amount cannot be zero");
        }

        return(false, "ok");
    }
    
    function createProposal( ActionType _actionType, address _actionAddress, uint8[] memory _percents, address[] memory _addresses, uint _amount) public {
        (bool error, string memory message) = beforeCreateProposal(_actionType, _actionAddress, _percents, _addresses, msg.sender, _amount);
        require (!error, message);

        uint time = block.timestamp + 5 minutes;//(3 * 24 hours); // Three days
        address[] memory emptyVoters;
        uint8[] memory emptyVotes;
        proposals.push(
            Proposal(time, 2,  _actionType, _actionAddress, _percents, _addresses, _amount, emptyVoters, emptyVotes)
        );
        emit ProposalCreated(time, _actionType, _actionAddress, _percents, _addresses, _amount, proposals.length-1);
    }
    
    function beforeVoteInProposal (uint proposalIndex, address senderAddress) public view returns(bool error, string memory description) {
        uint index = findParticipantIndex(senderAddress);
        if(index == 0)
            return(true, "You are not in participant");
        if(proposals.length <= proposalIndex)
            return(true, "Proposal not exist");
        if(proposals[proposalIndex].result != 2)
            return(true, "Proposal finished");
        if(block.timestamp >= proposals[proposalIndex].endTime)
            return(true, "Time for voting is out");

        for(uint i = 0; proposals[proposalIndex].voters.length > i; i++){
            if(proposals[proposalIndex].voters[i] == senderAddress){
                return(true, "You are already voted");
            }
        }
        return(false, "ok");
    }

    function voteInProposal (uint proposalIndex, uint8 vote) public{
        (bool error, string memory message) = beforeVoteInProposal(proposalIndex, msg.sender);
        require (!error, message);
        proposals[proposalIndex].voters.push(msg.sender);
        proposals[proposalIndex].votes.push(vote);
        emit Vote(proposals[proposalIndex].actionType, proposalIndex, msg.sender, vote);
    }

    function beforeFinishProposal (uint proposalIndex, address senderAddress) public view 
    returns(bool error, string memory message, uint votedYes, uint votedNo) {
        uint index = findParticipantIndex(senderAddress);
        uint _votedYes = 0;
        uint _votedNo = 0;
        
        for(uint i = 0; proposals[proposalIndex].voters.length > i; i++){
            if(proposals[proposalIndex].votes[i] == 1)
                _votedYes++;
            if(proposals[proposalIndex].votes[i] == 0)
                _votedNo++;
        }

        if(index == 0)
            return(true, "You are not in participant", _votedYes, _votedNo);
        if(proposals[proposalIndex].actionType == ActionType.add_voter && findParticipantIndex(proposals[proposalIndex].actionAddress) > 0)
            return(true, "This participant already exist", _votedYes, _votedNo);
        if(proposals[proposalIndex].actionType == ActionType.remove_voter && participants.length == 2)
            return(true, "Minimal count of voted participants is 2", _votedYes, _votedNo);
        if(proposals[proposalIndex].actionType == ActionType.remove_voter && participantPercent[proposals[proposalIndex].actionAddress] > 0)
            return(true, "The participant to delete must have zero percent", _votedYes, _votedNo);
        if(proposals.length <= proposalIndex)
            return(true, "Proposal does not exist", _votedYes, _votedNo);
        if(proposals[proposalIndex].result != 2)
            return(true, "Voting has finished", _votedYes, _votedNo);
        if(block.timestamp <= proposals[proposalIndex].endTime && proposals[proposalIndex].voters.length != participants.length)
            return(true, "Voting is not finished", _votedYes, _votedNo);
        if((proposals[proposalIndex].actionType == ActionType.eth_emission || proposals[proposalIndex].actionType == ActionType.eth_emission_single) && uni.balance < proposals[proposalIndex].amount)
            return(true, "Low ETH balance", _votedYes, _votedNo);  
        if(proposals[proposalIndex].actionType == ActionType.art_emission_single && IERC223(erc223).balanceOf(uni) < proposals[proposalIndex].amount)
            return(true, "Low ART balance", _votedYes, _votedNo);    
        if(proposals[proposalIndex].voters.length <= participants.length - proposals[proposalIndex].voters.length)
            return(true, "Voted participants must be more than 50%", _votedYes, _votedNo);
        return(false, "ok", _votedYes, _votedNo);
    }
    
    function finishProposal(uint proposalIndex) public {
        (bool error, string memory message, uint votedYes, uint votedNo) = beforeFinishProposal(proposalIndex, msg.sender);
        require (!error, message);

        proposals[proposalIndex].result = votedYes > votedNo? 1 : 0;

        if(votedYes > votedNo){
            if(proposals[proposalIndex].actionType == ActionType.add_voter){ // Add participant
                participants.push(proposals[proposalIndex].actionAddress);
            } 
            else if (proposals[proposalIndex].actionType == ActionType.remove_voter) { // Remove participant
                uint index = findParticipantIndex(proposals[proposalIndex].actionAddress) - 1;
                participants[index] = participants[participants.length-1];
                participants.pop();
            }
            else if (proposals[proposalIndex].actionType == ActionType.set_percent){
                for(uint i = 0; proposals[proposalIndex].addresses.length > i; i++){
                    participantPercent[proposals[proposalIndex].addresses[i]] = proposals[proposalIndex].percents[i];
                }
            }
            else if (proposals[proposalIndex].actionType == ActionType.eth_emission) { // Transfer ETH
                uint totalSend = proposals[proposalIndex].amount;
                uint remains = totalSend;
                for(uint i = 0; participants.length > i; i++){
                    if(i < participants.length-1){
                        IUNIART(uni).executeVoting(false, participants[i], totalSend/100*participantPercent[participants[i]]);
                        remains -= totalSend/100*participantPercent[participants[i]];
                    }
                    else{
                        IUNIART(uni).executeVoting(false, participants[i], remains);
                    }
                }
            }
            else if (proposals[proposalIndex].actionType == ActionType.art_emission_single) { // Transfer ART
                IUNIART(uni).executeVoting(true, proposals[proposalIndex].actionAddress, proposals[proposalIndex].amount);
            }
            else if (proposals[proposalIndex].actionType == ActionType.eth_emission_single) { // Transfer ETH
                IUNIART(uni).executeVoting(false, proposals[proposalIndex].actionAddress, proposals[proposalIndex].amount);
            }
        }
        emit FinishVoting(proposals[proposalIndex].actionType, votedYes > votedNo, proposalIndex);
    }

    function statusOfProposal (uint index) public view returns (address[] memory, uint8[] memory) {
        require(proposals.length > index, "Proposal not exist");
        return (proposals[index].voters, proposals[index].votes);
    }
    
    function getProposal(uint index) public view returns( uint endTime, uint8 result, ActionType actionType, address actionAddress, 
    uint8[] memory percents, address[] memory addresses, uint amount, address[] memory voters, uint8[] memory votes) {
        require(proposals.length > index, "Proposal not exist");
        Proposal memory p = proposals[index];
        return (p.endTime, p.result, p.actionType, p.actionAddress, p.percents, p.addresses, p.amount, p.voters, p.votes);
    }

    function proposalsLength () public view returns (uint) {
        return proposals.length;
    }

    function participantsLength () public view returns (uint) {
        return participants.length;
    }
    
    function percentagePayouts () public view returns (address[] memory participantsAdresses, uint8[] memory percents) {
        uint8[] memory pom = new uint8[](participants.length);
        for(uint i = 0; participants.length > i; i++){
            pom[i] = participantPercent[participants[i]];
        }
        return (participants, pom);
    }
    
    function findParticipantIndex(address addr) private view returns (uint) {
        for(uint i = 0; participants.length > i; i++){
            if(participants[i] == addr)
            return i+1;
        }
        return 0;
    }

    function info() public view returns (uint company, uint totalArt, uint eth) {
        if(uni == address(0))
            return (0,0,0);
        else
            return (IUNIART(uni).companyAmount(), IERC223(erc223).balanceOf(uni), uni.balance);
    }
}