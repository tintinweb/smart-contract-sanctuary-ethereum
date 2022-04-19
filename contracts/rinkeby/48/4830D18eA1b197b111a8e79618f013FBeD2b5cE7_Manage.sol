//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Voting.sol";


contract Manage {

    uint count;

    mapping(uint => Voting) public allVotes;

    //starting a vote
    function createVote(string memory _title)
    public {
        allVotes[count] = new Voting();
        count++;
    }

    // function startVoting(uint _id) 
    // public
    // returns(bool) {
    //     return true;
    // }

    // function stopVoting(uint _id) 
    // public
    // returns(bool) {
    //     return false;
    // }

    function castVote(uint _id, uint candidateID) 
    public {
        allVotes[_id].vote(candidateID);
    }

    function newCandidate(uint _id, string memory _name) 
    public {
        allVotes[_id].addCandidate(_name);
    }

    function getAllCandidates(uint _id) 
    public 
    view {
        allVotes[_id].getAllCandidates();
    }

    function compileResult(uint _id) 
    public 
    view {
        allVotes[_id].compileResult();
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Voting {
    //counter for every candidate; will form the id in the mapping
    uint256 candidateCount = 0;

    string title;
    //events for voting and add candidate
    event AddCandidate(string name);
    event Voted(uint256 id);

    //candidates information
    struct Candidate {
        uint id;
        string name;
        uint256 vote;
    }

    //mapping 
    mapping(uint256 => Candidate) public allCandidates;

    mapping(address => bool) public allVoters;


    // constructor (string memory _title) {
    //     title = _title;
    // }

    //addCandidate function
    //only the chairman can add a candidate
    function addCandidate(string memory _name) 
    external 
    returns(bool) {
        //create a new struct candidate
        //mapping the candidatecount as ID to the dandidate data
        allCandidates[candidateCount] = Candidate(candidateCount, _name, 0);
        //increment the count each time a candidate is added
        candidateCount++;

        //event
        emit AddCandidate(_name);


        return true;


    }


    //Voting function
    //takes the candidate of choices ID as argument
    function vote(uint _id)
    external {
        //require that the voter has not voted
        require(!allVoters[msg.sender]);

        //increment the candidates vote by 1
        allCandidates[_id].vote = allCandidates[_id].vote + 1;

        //mark the voter as having voted
        allVoters[msg.sender] = true;

        //emit the event
        emit Voted(_id);
    }


    //get all candidate
    function getAllCandidates()
    external 
    view
    returns(string[] memory, uint[] memory) {
        
        //names and ids to be returned
        string[] memory names = new string[](candidateCount);
        uint[] memory ids = new uint[](candidateCount);

        //iterate all the candidates
        //assign to the array at an index of their ID
        for(uint i = 0; i <= candidateCount; i++) {
            names[i] = allCandidates[i].name;
            ids[i] = allCandidates[i].id;
        }
        // return the arrays
        return(names, ids);
    }


    //getting results of vote
    function compileResult()
    external
    view
    returns(string[] memory, uint[] memory) {
        // array variables for names and vote of candidates
        string[] memory names = new string[](candidateCount);
        uint[] memory votes = new uint[](candidateCount);

        //iterate fot the candidates and votes
        for(uint i = 0; i <= candidateCount; i++) {
            names[i] = allCandidates[i].name;
            votes[i] = allCandidates[i].vote;
        }
        //return names and votes
        return(names, votes);
    }

}