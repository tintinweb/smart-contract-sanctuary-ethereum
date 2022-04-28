/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/** @title Simple Voting Contract */
/**
    @notice This contract allows a school to setup an election within its system
    @dev All function calls are currently implemented without side effects 
     */

contract SimpleVoting {
    /****************************************
    STATE VARIABLES
    *****************************************/

    /// @notice Public Variable to store the address of the chairman
    /// @dev Variable is of type address. The chairman has the supreme role of the stakeholders
    address public chairman; 

    /// @notice Public Variable to look up the addresses of stakeholders
    /// @dev mapping to lookup address in the stakeholder struct
    mapping (address => Stakeholder) public stakeholders; 
    
    /// @notice Public Variable to store list of all stakeholders that have been registered
    /// @dev an array of all the stakeholder addresses
    address[] public stakeholdersList; 

    /// @notice a list to hold all the board of directors registered by the Chairman
    /// @dev an array of all the board of directors addresses
    address[] public BODList; 

    /// @notice a list to hold all the teachers registered by the Chairman
    /// @dev an array of all the teachers addresses by the chairman
    address[] public teachersList; 
    
    /// @notice a list to hold all the students registered by the Chairman
    /// @dev an array of all the students addresses registered by the chairman
    address[] public studentList; //holds list of all students registered by the Chairman

    /// @notice a declaration of different roles available to be assigned to stakeholders
    /// @dev an enum to represent the possible roles an address can take.
    enum Role {
        BOD,
        TEACHER,
        STUDENT,
        CHAIRMAN
    } 


    Stakeholder[] public stakeholderObject; 

    /// @notice a way to store details of each stakeholder
    /// @dev a struct to store the details of each stakeholder
    /// @param role a variable to store the role of type enum 
    /// @param hasVoted a boolean to store whether a person has voted or not 
    /// @param candidateChosen a variable to show the candidate that was chosen
    /// @param registeredAddress address that registered stakeholder
    struct Stakeholder {
        Role role;
        bool hasVoted; 
        uint256 candidateChosen; 
        address registeredAddress;
        address stakeholderAddress;
    } 

    /// @notice a list of all candidates registered by the chairman
    /// @dev an array of all the candidates
    Candidate[] public candidatesList; 

    /// @notice a way to store details of each candidate
    /// @dev a struct to store the details of each candidate
    /// @param candidateID the id of the candidate
    /// @param candidateName name of the candidate
    /// @param registeredAddress address registered by the candidate
    /// @param totalVotesReceived total votes received
    /// @param votesReceivedBOD votes recieved from BOD
    /// @param votesReceivedTeachers votes received from teachers
    /// @param votesReceivedStudents votes received from students
    /// @param receivedChairmansVote votes received from chairman
    struct Candidate {
        uint256 candidateID;
        string candidateName;
        address registeredAddress;
        uint8 totalVotesReceived;
        uint8 votesReceivedBOD;
        uint8 votesReceivedTeachers;
        uint8 votesReceivedStudents;
        bool receivedChairmansVote;
    }

    /// @notice a variable to show the voting status, if it's active or not
    /// @dev a boolean to show if voting is active or not
    bool public votingActive;

    /// @notice a variable to show the results status, if it's public or not
    /// @dev a boolean to show if the results is public or not
    bool public resultsActive;

    
    /****************************************
    EVENTS
    *****************************************/

    /// @notice this event is emitted when an stakeholder is created.
    /// @param _address the address of the stakeholder
    /// @param message the uploaded message.
    /// @param _role the role of the stakeholder
    event CreateStakeholder(string message, address _address, uint256 _role);

    /// @notice this event is emitted when multiple stakeholders are created.
    /// @param _role the role of the stakeholders
    event CreateMultipleStakeHolders(string message, uint256 _role);

    /// @notice this event is emitted when a candidate is created.
    /// @param message the message of the event
    event CreateCandidate(string message);

    /// @notice this event is emitted when a candidate is voted for
    /// @param message the message of the event
    event Vote(string message);


    /// @notice a way to do some initializations at deployment
    /// @dev a constructor to do some initializations at deployment
    constructor() {
        chairman = msg.sender;
        votingActive = false;
        resultsActive = false;
        createStakeHolder(msg.sender, 3); //add the chairperson as a stakeholder
        BODList.push(msg.sender); //add the chairperson to the BOD LIST
    }

    //new function to allow chairman transfer his rights
    function transferChairman (address _address) public onlyByChairman {
        require (isABOD(_address), "Only BODs can be a chairman");
        chairman = _address;
        stakeholders[_address].role = Role(3); //change role of new chairman
        stakeholders[msg.sender].role = Role(0); //change role of old chairman
    }

    function getCurrentChairmanAddress() public view returns (address) {
        return chairman;
    }

    /// @notice create a stakeholder
    /// @dev initialize the stakeholders mapping to roles and push them into their respective arrays
    /// @param _address The address of the impending stakeholder
    /// @param _role parameter taking the input for the role to be assigned to the inputted address
    function createStakeHolder(address _address, uint256 _role)
        public
        onlyByChairman
    {
        require(!isAStakeholder(_address), "This address is already registered");
        //add stakeholders to the mapping
        stakeholders[_address] = Stakeholder(Role(_role), false, 8, msg.sender, _address); 
        //add stakeholders to the array that holds all structs of stakeholders
        stakeholderObject.push(stakeholders[_address]); 
        // add stakeholder's adress to the list of stakeHolders addresses
        stakeholdersList.push(_address); 
        //add stakeholder's adress to the corresponding list based on roles
        if (stakeholders[_address].role == Role(0)) {
            BODList.push(_address);
        }
        if (stakeholders[_address].role == Role(1)) {
            teachersList.push(_address);
        }
        if (stakeholders[_address].role == Role(2)) {
            studentList.push(_address);
        }

        emit CreateStakeholder("You just created a stakeholder", _address, _role);
    }

    /// @notice create multiple stakeholders
    /// @dev use a loop to add an array of addresses into respective roles
    /// @param _addressArray an array of impending stakeholder addresses
    /// @param _role parameter taking the input for the role to be assigned to the inputted address
    function createMultipleStakeHolders(address[] memory _addressArray, uint256 _role ) public onlyByChairman {
        for (uint256 i = 0; i < _addressArray.length; i++){
            createStakeHolder(_addressArray[i], _role);
        }

        emit CreateMultipleStakeHolders("You just created multiple stakeholders", _role);
    }
    
    /// @notice check if an address is a stakeholder
    /// @dev use a for loop to run the address through the array of stakeholder's list 
    /// @param _address address to be inputted to see if it's a stakeholder or not
    /// @return bool returns a boolean whether an address is a stakeholder or not
    function isAStakeholder(address _address) public view returns (bool) {
        for (uint8 i = 0; i < stakeholdersList.length; i++) {
            if (_address == stakeholdersList[i]) {
                return true;
            }
        }
        return false;
    }

    function isABOD(address _address) public view returns (bool) {
        for (uint8 i = 0; i < BODList.length; i++) {
            if (_address == BODList[i]) {
                return true;
            }
        }
        return false;
    }

    /// @notice create a candidate
    /// @dev a function to add a candidate
    /// @param _candidateName The name of the impending candidate
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
        emit CreateCandidate("You just added a new candidate");
    }

    /// @notice get list of candidates
    /// @dev a function to get list of candidates
    /// @return Candidate[] returns an array of candidate structs
    function getListOfCandidates() public view returns (Candidate[] memory) {
        return candidatesList;
    }

    /// @notice get list of stakeholders
    /// @dev a function to get list of stakeholders
    /// @return address[] returns an array of addresses
    function getListOfStakeHolders() public view returns (address[] memory) {
        return stakeholdersList;
    }

    function getListOfStakeHoldersObjects() public view returns (Stakeholder[] memory) {
        return stakeholderObject;
    }

    /// @notice get list of teachers
    /// @dev a function to get list of teachers
    /// @return address[] returns an array of addresses
    function getListOfTeachers() public view returns (address[] memory) {
        return teachersList;
    }

    /// @notice get list of students
    /// @dev a function to get list of students
    /// @return address[] returns an array of addresses
    function getListOfStudents() public view returns (address[] memory) {
        return studentList;
    }

    /// @notice get list of BODS
    /// @dev a function to get list of the BODS
    /// @return address[] returns an array of addresses
    function getListOfBOD() public view returns (address[] memory) {
        return BODList;
    }

    /// @notice convert a string to bytes
    /// @dev a function to convert a string to bytes
    /// @return bytes returns an a byte format of the string that was converted
    function toBytes(string memory _name) public pure returns (bytes memory) {
        return abi.encodePacked(_name);
    }

    /****************************************
    TOGGLE VOTING/RESULTS ON AND OFF
    *****************************************/    

    /// @notice toggle voting status
    /// @dev a function to toggle voting status, can only be called by the chairman
    /// @return bool returns a boolean
    function toggleVoting() public onlyByChairman returns (bool) {
        if (votingActive) {
            votingActive = false;
            return votingActive;
        } else {
            votingActive = true;
            return votingActive;
        }
    }
    
    /// @notice toggle result status
    /// @dev a function to toggle result status, can only be called by the chairman
    /// @return bool returns a boolean 
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

    
    /// @notice vote for a candidate
    /// @dev a function to vote a candidate
    /// @param _candidateID The id of the candidate you want to vote for
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

        emit Vote("You just voted a candidate");
    }

    /****************************************
    MODIFIERS
    *****************************************/

    /// @notice a restriction for functions that can only be called by the chairman
    /// @dev a modifier to restrict access to functions so only the chairman can call them
    modifier onlyByChairman() {
        require(msg.sender == chairman, "Only Chairman can do this.");
        _;
    }

    /// @notice a restriction for functions that can only be called by stakeholders
    /// @dev a modifier to restrict access to functions so only the stakeholders can call them
    modifier onlyStakeHolders() {
        require(isAStakeholder(msg.sender), "Is not registered to vote");
        _;
    }
}