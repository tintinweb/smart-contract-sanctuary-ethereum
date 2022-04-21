// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleVoting {
    //state variables
    address public chairman; //address of chairman

    //STAKEHOLDER VARIABLES
    mapping(address => Stakeholder) public stakeholders; //hold list of all stakeholders registered
    address[] public stakeholdersList; //hold list of all stakeholders registered

    address[] public BODList; //holds list of all board of directors registered by the Chairman
    address[] public teachersList; //holds list of all teachers registered by the Chairman
    address[] public studentList; //holds list of all students registered by the Chairman

    enum Role {
        BOD,
        TEACHER,
        STUDENT
    } //enum to rep the possible roles an address can take

    struct Stakeholder {
        Role role;
        bool voted; // if true, that person already voted
        uint256 candidateChosen; // index of the candidate voted for
        address registeredAddress; //address that registered stakeholder
    } // struct of the details for each stakeholder

    Candidate[] public candidatesList; //holds list of all candidates registered by the Chairman
    struct Candidate {
        uint256 candidateID;
        string candidateName;
        uint8 votesReceived;
        address registeredAddress; //address that registered candidate
        /*
        uint8 votesReceivedBOD
        uint8 votesReceivedTeachers
        uint8 votesReceivedStudents
        */
    } // struct of the details for each Cabdidates

    //Modifier
    modifier onlyByChairman() {
        require(msg.sender == chairman, "Only Chairman can do this.");
        _;
    }

    function isAStakeholder(address _address) public view returns (bool) {
        for (uint8 i = 0; i < stakeholdersList.length; i++) {
            if (_address == stakeholdersList[i]) {
                return true;
            }
        }
        return false;
    }

    function createStakeHolder(address _address, Role _role)
        public
        onlyByChairman
    {
        stakeholders[_address] = Stakeholder(_role, false, 8, msg.sender);
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
            Candidate(candidateID, _candidateName, 0, msg.sender)
        );
    }

    function getListOfCandidates() public view returns (Candidate[] memory) {
        return candidatesList;
    }

    constructor() {
        chairman = msg.sender;
        votingActive = false;
        resultsActive = false;
    }

    function toBytes(string memory _name) public pure returns (bytes memory) {
        return abi.encodePacked(_name);
    }

    //ENABLE AND DISABLE VOTING PROCESS ON OR OFF
    //ENABLE AND DISABLE VOTING PROCESS ON OR OFF
    //ENABLE AND DISABLE VOTING PROCESS ON OR OFF
    bool public votingActive;

    function toggleVoting() public onlyByChairman returns (bool) {
        if (votingActive) {
            votingActive = false;
            return votingActive;
        } else {
            votingActive = true;
            return votingActive;
        }
    }

    function vote(uint256 _candidateID) public onlyStakeHolders {
        stakeholders[msg.sender].voted = true;
        stakeholders[msg.sender].candidateChosen = _candidateID;

        Candidate memory chosenCandidate = candidatesList[_candidateID];
        chosenCandidate.votesReceived++;
        /*
        if (stakeholders[msg.sender].role == Role(0)){
            chosenCandidate.votesReceivedBOD++;
        }
        if (stakeholders[msg.sender].role == Role(1)){
            chosenCandidate.votesReceivedTeachers++;
        }
        if (stakeholders[msg.sender].role == Role(2)){
            chosenCandidate.votesReceivedStudents++;
        }
        */
    }

    modifier onlyStakeHolders() {
        require(isAStakeholder(msg.sender), "Is not registered to vote");
        _;
    }

    // ENABLE VIEWING RESUTLS ON AND OFF
    // ENABLE VIEWING RESUTLS ON AND OFF
    // ENABLE VIEWING RESUTLS ON AND OFF
    bool public resultsActive;

    function toggleResult() public onlyByChairman returns (bool) {
        if (resultsActive) {
            resultsActive = false;
            return resultsActive;
        } else {
            resultsActive = true;
            return resultsActive;
        }
    }
}