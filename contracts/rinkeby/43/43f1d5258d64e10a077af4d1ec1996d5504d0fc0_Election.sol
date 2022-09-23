/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Election {
    
    struct Topic {
        string name;
        bool registered;
        uint voteCount;
    }

    struct Voter {
        bool voted;
        bool registered;
        address vote;
    }

    address[] public topicAddresses;
    address public owner;
    string public electionName;

    mapping(address => Voter) public voters;
    mapping(address => Topic) public topic;
    uint public totalVotes;
    
    enum State { Created, Voting, Ended }
    State public state;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    modifier inState(State _state) {
        require(state == _state, "Wrong state");
        _;
    }

    constructor(string memory _name) {
        owner = msg.sender;
        electionName = _name; 
        state = State.Created;
    }
    

    function payFee() public payable {
        require(msg.value == 100 wei, "Pay 100 wei to register");
        topic[msg.sender].registered = true;        
    }
    

    function registerVoter(address _voterAddress) onlyOwner inState(State.Created) public {
        require(!voters[_voterAddress].registered, "Voter is already registered");
        require(_voterAddress != owner, "Owner cannot be registered");
        voters[_voterAddress].registered = true;
    }

    function addCandidate(address _topAddress, string memory _name) inState(State.Created) onlyOwner public {
        require(topic[_topAddress].registered, "Topic is not registered");
        topic[_topAddress].name = _name;
        topic[_topAddress].voteCount = 0;
        topicAddresses.push(_topAddress);
    }

    function startVote() public inState(State.Created) onlyOwner {
        state = State.Voting;
    }

    function vote(address _topAddress) inState(State.Voting) public {
        require(voters[msg.sender].registered, "Voter is not registered");
        require(!voters[msg.sender].voted, "Voter has already voted");
        require(topic[_topAddress].registered, "Not a registered candidate");
        require(msg.sender!=owner, "Owner cannot vote"); 

        voters[msg.sender].vote = _topAddress;
        voters[msg.sender].voted = true;
        topic[_topAddress].voteCount++;
        totalVotes++;
    }


    function endVote() public inState(State.Voting) onlyOwner {
        state = State.Ended;
    }

    function announceWinner() inState(State.Ended) onlyOwner public view returns (address) {
        uint max = 0;
        uint i;
        address winnerAddress;
        for(i=0; i<topicAddresses.length; i++) {
            if(topic[topicAddresses[i]].voteCount > max) {
                max = topic[topicAddresses[i]].voteCount;
                winnerAddress = topicAddresses[i];
            }
        }
        return winnerAddress;
    }

    function getTotalCandidates() public view returns(uint) {
        return topicAddresses.length;
    }

    function balanceOf() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawRegistrationFunds() onlyOwner inState(State.Ended) payable public {
        require(address(this).balance > 0, "No funds to transfer");
        payable(owner).transfer(address(this).balance);
    }
    
    function getOwnerBalance() public view returns(uint) {
        return owner.balance;
    }
    
}