// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ballot {

    //variables
    struct contestant {
        uint id;
        string name;
        uint voteCount;
        string party;
        uint age;
        string qualification; 
    }
    struct voter{
        bool isRegistered;
        bool hasVoted;
        uint vote;
    }

    mapping (uint => contestant) public contestants;
    // maps contestents;
    mapping (address => voter ) private voters;
    // maps voters with their block address
    uint public contestentsCount;
    address adminAddress;

    enum State{created, voting , ended}
    State public state;

    // modifiers
    modifier condition(bool _condition) {
        require(_condition);
        _;
    }
    modifier onlyOfficial() {
        require(msg.sender == adminAddress);
        _;
    }
    modifier inState(State _state) {
        require(state==_state);
        _;
    }
    //functions

    constructor() {
        adminAddress=msg.sender;
        state=State.created;
    }

    function changePhase(State _state)  onlyOfficial public {
        require(_state > state);
        state=_state;
    }

    function addConstestant(string memory _name , string memory _party , uint _age , string memory _qualification)  onlyOfficial inState(State.created) public{
        contestentsCount++;
        contestants[contestentsCount]=contestant(contestentsCount, _name, 0, _party, _age, _qualification);
    }

    function voterRegistration(address user) onlyOfficial inState(State.created) public {
        voters[user].isRegistered=true;
    }

    function vote(uint _contestant_id) public inState(State.voting){
        require(voters[msg.sender].isRegistered);
        require(!voters[msg.sender].hasVoted);
        require(_contestant_id>0 && _contestant_id<=contestentsCount);
        contestants[_contestant_id].voteCount++;
        voters[msg.sender].hasVoted=true;
		voters[msg.sender].vote=_contestant_id; 
    }
}