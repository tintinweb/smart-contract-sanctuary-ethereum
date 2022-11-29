// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <=0.9.0;

contract ElectionFact {
    struct ElectionDet {
        address deployedAddress;
        string el_n;
        string el_des;
    }

    mapping (string => ElectionDet) companyEmail;

    function createElection(string memory email, string memory election_name, string memory election_description) public {
        Election newelection = new Election(msg.sender, election_name, election_description);
        companyEmail[email].deployedAddress = address(newelection);
        companyEmail[email].el_n = election_name;
        companyEmail[email].el_des = election_description;
    }

    function getDeployedElection(string memory email) public view returns (address, string memory, string memory) {
        address val = companyEmail[email].deployedAddress;
        if(val == address(0)){
            return (address(0), "", "Create an election");
        }else {
            return (companyEmail[email].deployedAddress, companyEmail[email].el_n, companyEmail[email].el_des);
        }
    }
}

contract Election {
    //Election authority's address
    address election_authority;
    string election_name;
    string election_description;
    bool status;

    //election_authority's address taken when it deploys the contract
    constructor(address authority, string memory name, string memory description) {
        election_authority = authority;
        election_name = name;
        election_description = description;
        status = true;
    }

    //Only election_authority can call this function
    modifier owner() {
        require(msg.sender == election_authority, "Error: Access Denied");
        _;
    }

    //Candidate
    struct Candidate {
        string candidate_name;
        string candidate_date_of_birth;
        string candidate_description;
        string imgHash;
        uint8 voteCount;
        string email;
    }

    //Candidate mapping
    mapping (uint8 => Candidate) public candidates;

    //Voter
    struct Voter {
        uint8 candidate_id_voted;
        bool voted;
    }

    //Voter mapping
    mapping (string => Voter) voters;

    //Count the number of candidates
    uint8 numCandidates;

    //Count the number of voter
    uint8 numVoters;

    function addCandidate(string memory candidate_name,string memory candidate_date_of_birth ,
            string memory candidate_description, string memory imgHash,string memory email) public owner {
        uint8 candidateID = numCandidates++; // assign id of the candidate
        // add candidate to mapping
        candidates[candidateID] = Candidate(candidate_name, candidate_date_of_birth, candidate_description, imgHash, 0, email);
    }

    //function to vote and check for double voting
    function vote(uint8 candidateID,string memory email) public {
        // if false the vote will be registered
        require(!voters[email].voted, "Error:You cannot double vote"); 
        voters[email] = Voter(candidateID,true); //add the values to the mapping
        numVoters++;
        candidates[candidateID].voteCount++;//increment vote counter of candidate
    }

    //function to get candidate information
    function getCandidate(uint8 candidateID) public view returns (string memory, string memory, string memory, string memory, uint8,string memory) {
        return (candidates[candidateID].candidate_name,candidates[candidateID].candidate_date_of_birth , candidates[candidateID].candidate_description, candidates[candidateID].imgHash, candidates[candidateID].voteCount, candidates[candidateID].email);
    } 

    //function to return winner candidate information
    function winner() public view returns (uint8) {
        uint8 winnerID = 0;
        uint8 largestVotes = candidates[0].voteCount;
        for(uint8 i=1; i < numCandidates; i++){
            if(largestVotes < candidates[i].voteCount){
                largestVotes = candidates[i].voteCount;
                winnerID = i;
            }
        }
        return winnerID;
    } 

    //function to get count of candidates
    function getNumOfCandidates() public view returns(uint8) {
        return numCandidates;
    }

    //function to get count of voters
    function getNumOfVoters() public view returns(uint8) {
        return numVoters;
    }

    function getElectionDetails() public view returns(string memory, string memory) {
        return (election_name,election_description);    
    }



}