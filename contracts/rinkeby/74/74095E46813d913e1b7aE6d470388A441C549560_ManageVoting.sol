//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Voting.sol";
// import "./Token.sol";

contract ManageVoting {
    Voting voting;
    // Token token;

    address public owner;
    string[] public nameElections;
    bool isControlledVoting;

    //sets owner,
    //owner added as a stakeholder
    constructor(address _address) {
        // token = Token(_token);
        voting = Voting(_address);
        owner = msg.sender;
    }

    uint256 private electionsCount = 0;
    //EVENTS
    event CreateElection(address sender, string _electionName);
    event AddCandidate(address sender, string _electionName, string _name);
    event Vote(address sender, string _electionName, uint256 _candidateID);
    event ResultCompile(address sender);
    event EnableVoting(address sender);
    event StopVoting(address sender);

    event AddStakeholder(address sender);
    event AddBod(address sender);
    event AddStaff(address sender);
    event RemoveStakeholderRole(address sender);

    //MAPPING
    mapping(string => Voting) public elections;
    mapping(address => bool) public stakeholders;
    mapping(address => bool) public staff;
    mapping(address => bool) public bod;
    mapping(address => bool) public student;

    //MODIFIERS
    modifier onlyChairman() {
        require(msg.sender == owner, "Chairman only access");
        _;
    }

    // modifier staffOnly() {
    //     uint256 balance = token.balanceOf(msg.sender);
    //     require(balance > 99, "You are not a staff");
    //     _;
    // }

    // modifier bodOnly() {
    //     uint256 balance = token.balanceOf(msg.sender);
    //     require(balance > 199, "You are not a BOD");
    //     _;
    // }

    modifier stakeholderOnly() {
        require(stakeholders[msg.sender], "You are not a stakeholder");
        _;
    }

    //FUNCTIONS
    function transferChairmanRole(address _adr) public onlyChairman {
        owner = _adr;
    }

    function enableVoting(string memory _electionName) public onlyChairman {
        elections[_electionName].enableVoting();
        emit EnableVoting(msg.sender);
    }

    function disableVoting(string memory _electionName) public onlyChairman {
        elections[_electionName].disableVoting();
        emit StopVoting(msg.sender);
    }

    function allowResultCompile(string memory _electionName)
        public
        onlyChairman
    {
        elections[_electionName].allowResult();
        emit ResultCompile(msg.sender);
    }

    //add stakeholder
    function setStakeholders(address _adr) public onlyChairman returns (bool) {
        return stakeholders[_adr] = true;
    }

    //Create new instance of the voting contract
    //only chairman can create election
    function createElection(string memory _electionName, string memory category)
        public
        onlyChairman
        returns (bool)
    {
        Voting myVote = new Voting();
        elections[_electionName] = myVote;
        elections[_electionName].setVotingAccess(category);
        //increment the number of elections added
        electionsCount++;
        nameElections.push(_electionName);
        emit CreateElection(msg.sender, _electionName);
        return true;
    }

    //add candidate
    function addCandidate(
        string memory _electionName,
        string memory _name,
        string memory _img
    ) public onlyChairman returns (bool) {
        elections[_electionName].addCandidate(_name, _img);
        emit AddCandidate(msg.sender, _electionName, _name);
        return true;
    }

    //stakeholders only vote
    function vote(string memory _electionName, uint256 _candidateID)
        public
        returns (bool)
    {
        require(stakeholders[msg.sender], "You are not a stakeholder");

        // string memory va = elections[_electionName].getVotingAccess();

        // if (keccak256(bytes(va)) == keccak256(bytes("bod"))) {
        //     uint256 balance = token.balanceOf(msg.sender);
        //     require(
        //         balance > 199 * 10**18,
        //         "You are not a member of the board of directors"
        //     );
        // }

        // if (keccak256(bytes(va)) == keccak256(bytes("staff"))) {
        //     uint256 balance = token.balanceOf(msg.sender);
        //     require(
        //         balance > 99 * 10**18,
        //         "You are not a member of the staffs"
        //     );
        // }

        // if (keccak256(bytes(va)) == keccak256(bytes("student"))) {
        //     uint256 balance = token.balanceOf(msg.sender);
        //     require(balance < 99 * 10**18, "You are not a member of student");
        // }
        address voterAddress = msg.sender;
        elections[_electionName].vote(_candidateID, voterAddress);
        emit Vote(msg.sender, _electionName, _candidateID);
        return true;
    }

    //get list of all election
    function getAllElection() public view returns (string[] memory) {
        return nameElections;
    }

    //get list of all candidate for election name argument
    function getAllCandidate(string memory _electionName)
        public
        view
        returns (
            string[] memory,
            uint256[] memory,
            string[] memory
        )
    {
        return elections[_electionName].getAllCandidates();
    }

    //get result of an election name argument
    function getResults(string memory _electionName)
        public
        view
        returns (string[] memory, uint256[] memory)
    {
        return elections[_electionName].compileResult();
    }


    //number of voter
    function getNumberOfVoters(string memory _electionName) public view returns (uint) {
        return elections[_electionName].getNumberOfVoters();
    }


    //get voters voting status

    function getVoter(string memory _electionName) public view returns (bool) {
        address voterAddress = msg.sender;
        return elections[_electionName].getVoters(voterAddress);
    }

    function getVotingStatus(string memory _electionName)
    public
    view returns(Voting.VotingStatus) {
        return elections[_electionName].getVotingStatus();
    }


    function giveStaffRole(address _adr) public onlyChairman {
        // token.transfer(_adr, 100 * 10**18);
        stakeholders[_adr] = true;
        staff[_adr] = true;
        emit AddStaff(_adr);
    }

    function giveBodRole(address _adr) public onlyChairman {
        // token.transfer(_adr, 200 * 10**18);
        stakeholders[_adr] = true;
        bod[_adr] = true;
        emit AddBod(_adr);
    }

    function giveStakeholderRole(address _adr) public onlyChairman {
        // token.transfer(_adr, 10 * 10**18);
        stakeholders[_adr] = true;
        emit AddStakeholder(_adr);
    }

    function removeStakeholderRole(address _adr) public onlyChairman {
        stakeholders[_adr] = false;
        emit RemoveStakeholderRole(_adr);
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Voting {
    //counter for every candidate; will form the id in the mapping
    uint256 candidateCount = 0;

    //the state of the voting
    enum VotingStatus {
        ready,
        ongoing,
        ended,
        result
    }

    VotingStatus public status;

    string public votingAccess;

    uint public numberOfVoters;

    constructor() {
        status = VotingStatus.ready;
    }

    //EVENTS
    //events for voting and add candidate
    event AddCandidate(string name);

    //event for voting, takes in candidate ID
    event Voted(uint256 id);

    //candidates information
    struct Candidate {
        uint256 id;
        string name;
        uint256 vote;
        string imgUrl;
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
    modifier canVote(address adr) {
        require(!allVoters[adr], "You can vote only once");
        require(candidateCount > 0, "No candidate added");
        require(status == VotingStatus.ongoing, "Voting closed");
        _;
    }

    //which candidate is eligible
    modifier eligibleCandidate(string memory _name) {
        //a name can only be registered once
        require(!candidateNames[_name], "Name already exists");
        _;
    }

    //addCandidate function
    //only the chairman can add a candidate
    function addCandidate(string memory _name, string memory _imgUrl)
        external
        eligibleCandidate(_name)
    {
        //create a new struct candidate
        //mapping the candidatecount as ID to the dandidate data
        allCandidates[candidateCount] = Candidate(
            candidateCount,
            _name,
            0,
            _imgUrl
        );
        //increment the count each time a candidate is added
        candidateCount++;

        //sets users added
        candidateNames[_name] = true;

        //event
        emit AddCandidate(_name);
    }

    function setVotingAccess(string memory _name) public {
        votingAccess = _name;
    }

    function getVotingAccess() public view returns (string memory) {
        return votingAccess;
    }

    //get voters status
    function getVoters(address adr) public view returns (bool) {
        return allVoters[adr];
    }

    //number of voters
    function getNumberOfVoters() public view returns (uint) {
        return numberOfVoters;
    }

    
    //Voting function
    //takes the candidate of choices ID as argument
    function vote(uint256 _candidateID, address adr) external canVote(adr) returns (bool) {
        //increment the candidates vote by 1
        allCandidates[_candidateID].vote = allCandidates[_candidateID].vote + 1;

        //mark the voter as having voted
        allVoters[adr] = true;

        numberOfVoters = numberOfVoters + 1;
        //emit the event
        emit Voted(_candidateID);
        return true;
    }

    //get all candidate
    function getAllCandidates()
        external
        view
        returns (
            string[] memory,
            uint256[] memory,
            string[] memory
        )
    {
        //names and ids to be returned
        string[] memory names = new string[](candidateCount);
        uint256[] memory ids = new uint256[](candidateCount);
        string[] memory imgUrl = new string[](candidateCount);

        //iterate all the candidates
        //assign to the array at an index of their ID
        for (uint256 i = 0; i < candidateCount; i++) {
            Candidate storage candi = allCandidates[i];
            names[i] = candi.name;
            ids[i] = candi.id;
            imgUrl[i] = candi.imgUrl;
        }
        // return the arrays
        return (names, ids, imgUrl);
    }

    //getting results of vote
    function compileResult()
        external
        view
        returns (string[] memory, uint256[] memory)
    {
        //result can only be seen if status is "result"
        require(status == VotingStatus.result, "You can't view result yet");
        // array variables for names and vote of candidates
        string[] memory names = new string[](candidateCount);
        uint256[] memory votes = new uint256[](candidateCount);

        //iterate fot the candidates and votes
        for (uint256 i = 0; i < candidateCount; i++) {
            //stores data in a struct variable
            Candidate storage candi = allCandidates[i];
            names[i] = candi.name;
            votes[i] = candi.vote;
        }
        //return names and votes
        return (names, votes);
    }

    //enable voting function
    function enableVoting() public {
        status = VotingStatus.ongoing;
    }

    // disableVoting function
    function disableVoting() public {
        status = VotingStatus.ended;
    }

    //allowing for compile result
    function allowResult() public {
        status = VotingStatus.result;
    }

    //get election status
    function getVotingStatus() public view returns (VotingStatus) {
        
        
        return status;
    }
}