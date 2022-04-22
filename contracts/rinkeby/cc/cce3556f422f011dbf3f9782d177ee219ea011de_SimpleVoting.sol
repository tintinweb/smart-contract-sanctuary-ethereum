/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleVoting {
    /****************************************
    STATE VARIABLES
    *****************************************/
    address public chairman; //address of chairman

    mapping(address => Stakeholder) public stakeholders; //hold list of all stakeholders registered
    address[] public stakeholdersList; //hold list of all stakeholders registered

    address[] public BODList; //holds list of all board of directors registered by the Chairman
    address[] public teachersList; //holds list of all teachers registered by the Chairman
    address[] public studentList; //holds list of all students registered by the Chairman

    enum Role {
        BOD,
        TEACHER,
        STUDENT,
        CHAIRMAN
    } //enum to rep the possible roles an address can take

    struct Stakeholder {
        Role role;
        bool hasVoted; // if true, that person already voted
        uint256 candidateChosen; // index of the candidate voted for
        address registeredAddress; //address that registered stakeholder
    } // struct of the details for each stakeholder

    Candidate[] public candidatesList; //holds list of all candidates registered by the Chairman

    struct Candidate {
        uint256 candidateID;
        string candidateName;
        address registeredAddress; //address that registered candidate
        uint8 totalVotesReceived;
        uint8 votesReceivedBOD;
        uint8 votesReceivedTeachers;
        uint8 votesReceivedStudents;
        bool receivedChairmansVote;
    } // struct of the details for each Cabdidates

    bool public votingActive;

    bool public resultsActive;

    constructor() {
        chairman = msg.sender;
        votingActive = false;
        resultsActive = false;
        createStakeHolder(msg.sender, 3); //add the chairperson as a stakeholder
    }

    function createStakeHolder(address _address, uint256 _role)
        public
        onlyByChairman
    {
        stakeholders[_address] = Stakeholder(Role(_role), false, 8, msg.sender); //add stakeholders to the mapping
        stakeholdersList.push(_address); // add stakeholder's adress to the list of stakeHolders addresses
        if (stakeholders[_address].role == Role(0)) {
            BODList.push(_address);
        }
        if (stakeholders[_address].role == Role(1)) {
            teachersList.push(_address);
        }
        if (stakeholders[_address].role == Role(2)) {
            studentList.push(_address);
        }
    }

    function isAStakeholder(address _address) public view returns (bool) {
        for (uint8 i = 0; i < stakeholdersList.length; i++) {
            if (_address == stakeholdersList[i]) {
                return true;
            }
        }
        return false;
    }

    function createCandidate(string memory _candidateName)
        public
        onlyByChairman
    {
        uint256 candidateID;
        if (candidatesList.length == 0) {
            candidateID = 0;
        } else {
            candidateID = candidatesList.length;
        }
        // bytes memory candidateName = toBytes(_candidateName);
        candidatesList.push(
            Candidate(candidateID, _candidateName, msg.sender, 0, 0, 0, 0, false)
        );
    }

    function getListOfCandidates() public view returns (Candidate[] memory) {
        return candidatesList;
    }

    function getListOfStakeHolders() public view returns (address[] memory) {
        return stakeholdersList;
    }

    function getListOfTeachers() public view returns (address[] memory) {
        return teachersList;
    }

    function getListOfStudents() public view returns (address[] memory) {
        return studentList;
    }


    function getListOfBOD() public view returns (address[] memory) {
        return BODList;
    }

    function toBytes(string memory _name) public pure returns (bytes memory) {
        return abi.encodePacked(_name);
    }

    /****************************************
    TOGGLE VOTING/RESULTS ON AND OFF
    *****************************************/    
    function toggleVoting() public onlyByChairman returns (bool) {
        if (votingActive) {
            votingActive = false;
            return votingActive;
        } else {
            votingActive = true;
            return votingActive;
        }
    }

    function toggleResult() public onlyByChairman returns (bool) {
        if (resultsActive) {
            resultsActive = false;
            return resultsActive;
        } else {
            resultsActive = true;
            return resultsActive;
        }
    }

    /****************************************
    ENABLE A STAKEHOLDER TO VOTE
    *****************************************/

    function vote (uint256 _candidateID) public onlyStakeHolders {
        require(stakeholders[msg.sender].hasVoted == false, "You have voted before");
        require(votingActive == true, "Voting Session is not active");
        stakeholders[msg.sender].hasVoted = true; //mark that this stakeholder has voted
        stakeholders[msg.sender].candidateChosen = _candidateID; //store who this stakeholder voted for

        candidatesList[_candidateID].totalVotesReceived = candidatesList[_candidateID].totalVotesReceived + 1;
        
        if (stakeholders[msg.sender].role == Role(0)){
            candidatesList[_candidateID].votesReceivedBOD = candidatesList[_candidateID].votesReceivedBOD + 1;
        }
        if (stakeholders[msg.sender].role == Role(1)){
            candidatesList[_candidateID].votesReceivedTeachers = candidatesList[_candidateID].votesReceivedTeachers + 1;
        }
        if (stakeholders[msg.sender].role == Role(2)){
            candidatesList[_candidateID].votesReceivedStudents = candidatesList[_candidateID].votesReceivedStudents + 1;
        }
        if (msg.sender == chairman){
            candidatesList[_candidateID].receivedChairmansVote = true;
        }
    }

    /****************************************
    MODIFIERS
    *****************************************/

    modifier onlyByChairman() {
        require(msg.sender == chairman, "Only Chairman can do this.");
        _;
    }

        modifier onlyStakeHolders() {
        require(isAStakeholder(msg.sender), "Is not registered to vote");
        _;
    }
}