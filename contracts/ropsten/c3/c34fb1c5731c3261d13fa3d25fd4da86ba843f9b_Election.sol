/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
// import "hardhat/console.sol";
contract Election  {
    struct Candidate {
        uint id;
        string name;
        string party;
        uint voteCount;
    }
    struct CandidatePole {
        string party;
        uint voteCount;
    }
    bool goingOn = true;
    Candidate[] candidate;
    Candidate[] votingCandidate;
    mapping(address => bool) private voters;
    mapping(uint => Candidate) private candidates;
    uint private candidatesCount;
   
    event votedEvent (address indexed voterAddress, 
        uint indexed _candidateId
    ); 

    constructor () {
        addCandidate("Candidate 1", "Venus");
        addCandidate("Candidate 2", "Earth");
        addCandidate("Candidate 3", "Jupiter");
        addCandidate("Candidate 4", "Saturn");
        addCandidate("None of above", "Nota");
    }

    function addCandidate (string memory _name, string memory _party) private {
        candidatesCount ++;
        Candidate memory userCandidate = Candidate(candidatesCount, _name, _party, 0);
        candidates[candidatesCount] = Candidate(candidatesCount, _name, _party, 0);
        candidate.push(userCandidate);
    }

    function endVoting () public {
        goingOn = false;
    }
    function startVoting () public {
        goingOn = true;
    }

    function voting (address voterAddress,uint _candidateId) public {

        require(msg.sender == voterAddress,"Invalide Biomatric!!");

        require(!voters[voterAddress],"Already voted");

        require(_candidateId > 0 && _candidateId <= candidatesCount,"Invalid candidate");

        require(goingOn,"Election ended");

        voters[voterAddress] = true;
        candidates[_candidateId].voteCount ++;
        emit votedEvent(voterAddress,_candidateId);
    }

    function getCandidateByID(uint _candidateId) public view returns(Candidate memory){
        uint i;
        for(i=0;i<= candidate.length;i++){
            Candidate memory _userCandidate = candidates[i];
           if(_userCandidate.id == _candidateId)
           {
                  return(_userCandidate);
           }
        }
        Candidate memory _candidate = Candidate(0,"Not Found","Not Found",0);
        return(_candidate);
    }
    function getAllCandidate() public view returns(Candidate[] memory){  
        uint count = candidatesCount+1;
        Candidate[] memory _userCandidate = new Candidate[](candidatesCount+1);
        for(uint i=0; i < count; i++){
             _userCandidate[i] = candidates[i];
        }
         return _userCandidate;
    }
}