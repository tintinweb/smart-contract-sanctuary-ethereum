//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting {

    ///VARIABLES

    struct candidate {
        uint votes;
        bool exists;
    }

    struct voting {
        mapping (address => address) voters;
        mapping (address => candidate) candidates;
        address[] candidatesAddr;
        address winner;
        uint maxVotes;
        uint votesAmount;
        uint finishTime;
        bool continues;
    }

    mapping (uint => voting) public votings;

    uint public fee = 1e16;
    uint public comission = 10;
    uint public balance;
    address public owner;
    uint public votingDuration = 259200;

    ///EVENTS

    event votingFinish(uint indexed _index, address indexed _address, uint _prize);
    event transfered (address indexed _to, uint _value);

    ///MODIFIERS

    modifier ownerOnly {
        require(msg.sender == owner, "You are not an owner");
        _;
    }

    modifier votable(uint _index, address _candidate) {
        require(votings[_index].continues, "Voting doesn't exist");
        require(votings[_index].finishTime > block.timestamp, "Voting already finished");
        require(votings[_index].candidates[_candidate].exists, "Candidate not found");
        require(msg.value == fee, "Transfer 0.01 ETH");
        require(votings[_index].voters[msg.sender] == address(0), "You have already voted");
        _;
    }

    ///FUNCTIONS

    constructor() {
        owner = msg.sender;
    }

    function createVoting (uint _index, address[] memory _candidates)
    external
    ownerOnly
    {
        require(!votings[_index].continues, "This index is taken!");
        require(_candidates.length > 1, "Must have at least two candidates!");

        for (uint i = 0; i < _candidates.length; i++) {
            votings[_index].candidates[_candidates[i]].exists = true;
            votings[_index].candidatesAddr.push(_candidates[i]);
        }

        votings[_index].continues = true;
        votings[_index].finishTime = block.timestamp + votingDuration;
    }

    function vote(uint _index, address _candidate) 
    payable 
    external 
    votable(_index, _candidate) 
    {
        votings[_index].candidates[_candidate].votes++;
        votings[_index].voters[msg.sender] = _candidate;
        votings[_index].votesAmount++;
        if (votings[_index].candidates[_candidate].votes > votings[_index].maxVotes) {
            votings[_index].maxVotes = votings[_index].candidates[_candidate].votes;
            votings[_index].winner = _candidate;
        }
    }

    function endVoting(uint _index)
    external
    {
        require(votings[_index].continues, "Voting not found!");
        require(votings[_index].finishTime <= block.timestamp, "Voting can't be finished now");
    
        votings[_index].continues = false;

        if (votings[_index].votesAmount == 0)
            return;

        uint _prize = votings[_index].votesAmount * fee * (100 - comission) / 100;

        emit votingFinish(_index, votings[_index].winner, _prize);
        address payable _to = payable(votings[_index].winner);
        _to.transfer(_prize);
        emit transfered(_to, _prize);
        balance += votings[_index].votesAmount * fee * comission / 100;
    }

    function transferBalance(address payable _to, uint _value)
    public
    ownerOnly
    {
        require(_value <= balance, "Not enough balance to transfer");
        _to.transfer(_value);
        emit transfered(_to, _value);
        balance -= _value;
    }

    function candidatesInfo(uint _index)
    public
    view
    returns(address[] memory)
    {
        return votings[_index].candidatesAddr;
    }

    function votesInfo(uint _index, address _candidate)
    external
    view
    returns(uint)
    {
        return votings[_index].candidates[_candidate].votes;

    }

    function getBalance()
    external
    view
    returns(uint)
    {
        return address(this).balance;
    }

    function endInfo (uint _index)
    public
    view
    returns(int)
    {
        return int(votings[_index].finishTime - block.timestamp);
    }
}