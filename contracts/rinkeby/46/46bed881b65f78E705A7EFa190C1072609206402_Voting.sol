//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Voting {
    //counter for every candidate; will form the id in the mapping
    uint256 candidateCount = 0;

    //enable/disable voting
    bool public votingStatus = true;

    //EVENTS
    //events for voting and add candidate
    event AddCandidate(string name);

    //event for voting, takes in candidate ID
    event Voted(uint256 id);

    //candidates information
    struct Candidate {
        uint id;
        string name;
        uint256 vote;
    }

    //MAPPING
    //maps all candidate
    mapping(uint256 => Candidate) allCandidates;
    
    //maps address of all stakeholder that vote
    mapping(address => bool) allVoters;

    //maps for every  name
    mapping(string => bool) candidateNames;

    //MODIFIERS

    //checks for who can vote
    //user can only vote once
    //Voting must be enabled
    modifier canVote {
        require(!allVoters[msg.sender], "You can vote only once");
        require(candidateCount > 0, "No candidate added");
        require(votingStatus, "Voting closed");
        _;
    }

    //which candidate is eligible
    modifier eligibleCandidate(string memory _name) {
            //a name can only be registered once
            require(!candidateNames[_name], "Name already exists"  );
            _;
    }


    //addCandidate function
    //only the chairman can add a candidate
    function addCandidate(string memory _name) 
    eligibleCandidate(_name)
    external  {

        //create a new struct candidate
        //mapping the candidatecount as ID to the dandidate data
        allCandidates[candidateCount] = Candidate(candidateCount, _name, 0);
        //increment the count each time a candidate is added
        candidateCount++;

        //sets users added
        candidateNames[_name] = true;

        //event
        emit AddCandidate(_name);

    }



    //Voting function
    //takes the candidate of choices ID as argument
    function vote(uint _candidateID)
    canVote()
    external 
    returns(bool) {

        //increment the candidates vote by 1
        allCandidates[_candidateID].vote = allCandidates[_candidateID].vote + 1;

        //mark the voter as having voted
        allVoters[msg.sender] = true;

        //emit the event
        emit Voted(_candidateID);
        return true;
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
        for(uint i = 0; i < candidateCount; i++) {
            Candidate storage candi = allCandidates[i];
            names[i] = candi.name;
            ids[i] = candi.id;
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
        for(uint i = 0; i < candidateCount; i++) {
            //stores data in a struct variable
            Candidate storage candi = allCandidates[i];
            names[i] = candi.name;
            votes[i] = candi.vote;
        }
        //return names and votes
        return(names, votes);
    }

    //enable voting function
    function enableVoting()
    public {
        votingStatus = true;
    }

    // disableVoting function
    function disableVoting()
    public {
        votingStatus = false;
    }

}