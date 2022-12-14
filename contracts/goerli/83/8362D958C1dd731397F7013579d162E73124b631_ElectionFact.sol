// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <=0.9.0;

contract ElectionFact {
    struct ElectionDet {
        address deployedAddress;
        string el_n;
        string el_des;
    }

    //Event
    event CreateElection(address deployedAddress);

    mapping (string => ElectionDet) companyEmail;

    function createElection(string memory email, string memory election_name, string memory election_description) public {
        Election newelection = new Election(msg.sender, election_name, election_description);
        companyEmail[email].deployedAddress = address(newelection);
        companyEmail[email].el_n = election_name;
        companyEmail[email].el_des = election_description;
        emit CreateElection(address(newelection));
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

     //Count the number of position
    uint8 numPosition;

    mapping (uint8 => string) positions;

    //Candidate
    struct Candidate {
        string candidate_name;
        string candidate_date_of_birth;
        string candidate_description;
        string imgHash;
        uint8 voteCount;
        uint8 position_id;
        string email;
    }

    //Candidate mapping
    mapping (uint8 => Candidate) public candidates;

    //Voter
    struct Voter {
        bool voted;
        uint8[] candidateIDList;
    }

    //Voter mapping
    mapping (string => Voter) voters;

    //Count the number of candidates
    uint8 numCandidates;

    //Count the number of voter
    uint8 numVoters;

    //Events
    event AddPosition(uint8 positionID, string position_name);
    event AddCandidate(uint8 candidateID, string candidate_name, string candidate_date_of_birth, string candidate_description, 
    string imgHash, uint8 voteCount, uint8 positionID, string email);
    event Vote(uint8[] candidateIDList);

    //Add Candidate
    function addCandidate(string memory candidate_name,string memory candidate_date_of_birth ,
            string memory candidate_description, string memory imgHash, uint8 positionID ,string memory email) public owner{
        uint8 candidateID = numCandidates++; // assign id of the candidate
        // add candidate to mapping
        candidates[candidateID] = Candidate(candidate_name, candidate_date_of_birth, candidate_description, imgHash, 0, positionID, email);
        emit AddCandidate(candidateID, candidate_name, candidate_date_of_birth, candidate_description, imgHash, 0, positionID, email);
    }

    //Function add Position
    function addPosition(string memory _position_name) public {
        uint8 positionID = numPosition++;
        positions[positionID] = _position_name;
        emit AddPosition(positionID, _position_name);
    }

    //function to vote and check for double voting
    function vote(uint8[] memory _candidateIDList,string memory email) public {
        // if false the vote will be registered
        require(!voters[email].voted, "Error:You cannot double vote"); 
        voters[email] = Voter(true, _candidateIDList);
        for(uint8 i = 0; i < _candidateIDList.length; i++){
            numVoters++;
            candidates[_candidateIDList[i]].voteCount++;//increment vote counter of candidate
        } //add the values to the mapping
        emit Vote(_candidateIDList);
    }

    function getPositions() public view returns (string[] memory){
        string[] memory _positions = new string[](numPosition);
        for(uint8 i = 0; i < numPosition; i++) {
            _positions[i] = positions[i];
        }
        return _positions;

    }

    function getVoter(string memory email) public view returns (Voter memory){
        return voters[email];
    }

    //function to get candidate information
    function getCandidate(uint8 candidateID) public view returns (string memory, string memory, string memory, string memory, uint8,string memory) {
        return (candidates[candidateID].candidate_name,candidates[candidateID].candidate_date_of_birth , candidates[candidateID].candidate_description, candidates[candidateID].imgHash, candidates[candidateID].voteCount, candidates[candidateID].email);
    } 

   //function to return winner candidate information
    function winner() public view returns (int8[] memory) {
        int8[] memory winnerIDList = new int8[](numPosition);
        for(uint8 i = 0; i < numPosition; i++) {
            int8 winnerID = -1;
            uint8 largestVotes = 0;
            for(uint8 j = 0; j < numCandidates; j++){
                if(largestVotes < candidates[j].voteCount && candidates[j].position_id == i){
                    largestVotes = candidates[j].voteCount;
                    winnerID = int8(j);
                }
            }
            winnerIDList[i] = winnerID;
        }
        return winnerIDList;
    } 

    //function to get count of candidates
    function getNumOfCandidates() public view returns(uint8) {
        return numCandidates;
    }

    //function to get count of voters
    function getNumOfVoters() public view returns(uint8) {
        return numVoters;
    }

    function getNumOfPosition() public view returns(uint8) {
        return numPosition;
    }

    function getElectionDetails() public view returns(string memory, string memory) {
        return (election_name,election_description);    
    }

}