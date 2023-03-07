// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Voting {

    address public owner;
    address public winnerAddress;
    string public eventName;
    uint public totalVote;
    bool votingStarted;

    struct Candidate{
        string name;
        uint age;
        bool registered;
        address candidateAddress;
        uint votes;
    }

    struct Voter{
        bool registered;
        bool voted;
    }

    event success(string msg);
    mapping(address=>uint) public candidates;
    Candidate[] public candidateList;
    mapping(address=>Voter) public voterList;

    constructor(string memory _eventName){
        owner = msg.sender;
        eventName = _eventName;
        totalVote = 0;
        votingStarted=false;
    }

    function registerCandidates(string memory _name, uint _age, address _candidateAddress) public {
        require(msg.sender == owner, "Only owner can register Candidate!!");
        require(_candidateAddress != owner, "Owner can not participate!!");
        require(candidates[_candidateAddress] == 0, "Candidate already registered");
        Candidate memory candidate = Candidate({
            name: _name,
            age: _age,
            registered: true,
            votes: 0,
            candidateAddress: _candidateAddress
        });
        if(candidateList.length == 0){ //not pushing any candidate on location zero;
            candidateList.push();
        }
        candidates[_candidateAddress] = candidateList.length;
        candidateList.push(candidate);
        emit success("Candidate registered!!");
    }

    function whiteListAddress(address _voterAddress) public {
        require(_voterAddress != owner, "Owner can not vote!!");
        require(msg.sender == owner, "Only owner can whitelist the addresses!!");
        require(voterList[_voterAddress].registered == false, "Voter already registered!!");
        Voter memory voter = Voter({
            registered: true,
            voted: false
        });

        voterList[_voterAddress] = voter;
        emit success("Voter registered!!");
    }

    function startVoting() public {
        require(msg.sender == owner, "Only owner can start voting!!");
        votingStarted = true;
        emit success("Voting Started!!");
    }

    function putVote(address _candidateAddress) public {
        require(votingStarted == true, "Voting not started yet or ended!!");
        require(msg.sender != owner, "Owner can not vote!!");
        require(voterList[msg.sender].registered == true, "Voter not registered!!");
        require(voterList[msg.sender].voted == false, "Already voted!!");
        require(candidateList[candidates[_candidateAddress]].registered == true, "Candidate not registered");

        candidateList[candidates[_candidateAddress]].votes++;
        voterList[msg.sender].voted =true;

        uint candidateVotes = candidateList[candidates[_candidateAddress]].votes;

        if(totalVote < candidateVotes){
            totalVote = candidateVotes;
            winnerAddress = _candidateAddress;
        }
        emit success("Voted !!");
        
    }

    function stopVoting() public {
        require(msg.sender == owner, "Only owner can start voting!!");
        votingStarted = false;
        emit success("Voting stoped!!");
    }

    function getAllCandidate() public view returns(Candidate[] memory list){
        return candidateList;
    }

    function votingStatus() public view returns(bool){
        return votingStarted;
    }

    function getWinner() public view returns(Candidate memory candidate){
        require(msg.sender == owner, "Only owner can declare winner!!");
        return candidateList[candidates[winnerAddress]];
    }
}