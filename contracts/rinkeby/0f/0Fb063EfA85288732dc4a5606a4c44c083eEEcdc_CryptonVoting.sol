/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// contract for Crypton by ilkatel
contract CryptonVoting {

    event Transfer(address indexed _to, uint _value);
    event Winner(uint indexed _index, address indexed _address, uint _prize);

    struct Candidate {
        uint votes;
        bool exist;
    }

    struct VotingProcess {
        mapping(address => address) voters;
        mapping(address => Candidate) candidates;
        address[] allCandidates;
        address winner;
        uint allVotes;
        uint maxVotes;
        uint finishTime;
        bool inProcess;  // true if voting in progress; false if voting finished or non-existent
    }
    
    mapping(uint => VotingProcess) public vp;
    uint public votingDuration; // 259_200;  // 3 * 24 * 60 * 60
    uint public votePrice = 1e16;  // 0.01 ETH
    uint public comission = 10;  // 10%
    uint public freeBalance;  // balance that can be withdrawn by the owner
    address private owner;
    

    constructor(uint _votingDuration) {
        owner = msg.sender;
        votingDuration = _votingDuration;
    }
    

    modifier isOwner {
        require(msg.sender == owner, "You are not an owner!");
        _;
    }

    modifier canVote(uint _index, address _candidate) {
        require(vp[_index].inProcess, "No such voting!");
        require(vp[_index].finishTime > block.timestamp, "This vote is over!");
        require(msg.sender != _candidate, "You cant vote for yourself!");
        require(vp[_index].candidates[_candidate].exist, "No such candidate!");
        require(msg.value == votePrice, "Incorrect voting prise!");
        require(vp[_index].voters[msg.sender] == address(0), "You have already voted!");
        _;
    }

    function addVoting(uint _index, address[] memory _candidates) external isOwner {
        require(!vp[_index].inProcess, "This index is taken!");
        require(_candidates.length > 1, "Must have at least two candidates!");

        for (uint i = 0; i < _candidates.length; i++) {
            // Find duplicates and revert tx if they exists
            require(!vp[_index].candidates[_candidates[i]].exist, "Dont use duplicates when adding candidates!");
            vp[_index].candidates[_candidates[i]].exist = true;
            vp[_index].allCandidates.push(_candidates[i]);
        }

        vp[_index].inProcess = true;
        vp[_index].finishTime = block.timestamp + votingDuration;
    }

    function vote(uint _index, address _candidate) payable external canVote(_index, _candidate) {
        // Vote
        vp[_index].candidates[_candidate].votes++;
        vp[_index].voters[msg.sender] = _candidate;
        vp[_index].allVotes++;

        // Update winner
        // The winner is the candidate who receives the maximum number of votes first
        // Winner can be only one
        if (vp[_index].candidates[_candidate].votes > vp[_index].maxVotes) {
            vp[_index].maxVotes = vp[_index].candidates[_candidate].votes;
            vp[_index].winner = _candidate;
        }
    }

    function transfer(address _to, uint _value) internal {
        payable(_to).transfer(_value);
        emit Transfer(_to, _value);
    }

    function finishVoting(uint _index) public {
        require(vp[_index].inProcess, "Voting not found!");
        require(vp[_index].finishTime <= block.timestamp, "Cant finish voiting yet!");

        vp[_index].inProcess = false;
        // If voting has no votes, return this function
        if (vp[_index].allVotes == 0)
            return;
        
        uint _prize = vp[_index].allVotes * votePrice * (100 - comission) / 100;
        emit Winner(_index, vp[_index].winner, _prize);
        transfer(vp[_index].winner, _prize);
        freeBalance += vp[_index].allVotes * votePrice * comission / 100;
    }

    function withdraw(uint _value) public isOwner {
        require(_value <= freeBalance, "Value is out of free balance!");
        require(_value != 0, "Cant withdraw null value!");

        transfer(owner, _value);
        freeBalance -= _value;
    }

    function getCandidates(uint _index) public view returns(address[] memory) {
        return vp[_index].allCandidates;
    }

    function getVotes(uint _index, address _candidate) public view returns(uint) {
        return vp[_index].candidates[_candidate].votes;
    }

    function getWinner(uint _index) public view returns(address) {
        return vp[_index].winner;
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getTimeLeft(uint _index) public view returns(int) {
        return int(vp[_index].finishTime - block.timestamp);
    }
}