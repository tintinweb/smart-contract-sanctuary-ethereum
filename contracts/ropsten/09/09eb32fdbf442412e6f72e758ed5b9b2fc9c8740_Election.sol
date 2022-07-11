/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        address candidate_address;
        string name;
        uint voteCount;
        bool approved;
        string image_addr;

    }
    address public contract_owner;
    uint256 wei_received;
    bool public gift_claimed;


    // Store accounts that have voted
    mapping(address => bool) public voters;
    mapping(uint => address) private votersmap;
    uint private votersCount;
    uint public approved_candidates_count;

    // Fetch Candidate
    mapping(uint => Candidate) public candidates;

    mapping(address => uint) public addressmap;
    // Store Candidates Count
    uint public candidatesCount;
    uint public endTime;
    uint public startTime;
    bool public votingProcess;

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );
    modifier onlyAdmin(){
        require(contract_owner == msg.sender, "Admin Permission");
        _;
    }
    modifier votingPeriod(){
        require (startTime <= block.timestamp && block.timestamp <= endTime, "Voting Time Error");
        _;
    }
    modifier sufficientBalance() {
        require (address(this).balance >=1, "Insufficient balance");
        _;
    }
    constructor () payable {
        contract_owner =  msg.sender;
        votingProcess = false;
        wei_received = msg.value;
    }

    function registerCandidate (string memory _name, string memory _imgAddr) public {
        // require that they haven't registered before
        require(addressmap[msg.sender] == 0, "Already Registered");
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount,msg.sender, _name, 0, false, _imgAddr);
        addressmap[msg.sender] = candidatesCount;
    }

    function approve (uint _candidateId) public onlyAdmin{
        require (candidates[_candidateId].id >= 1 && candidates[_candidateId].approved == false, "Already approved");
        candidates[_candidateId].approved = true;
        approved_candidates_count++;
    }

    function startVote(uint _voteMinutes) public onlyAdmin {
        require(candidatesCount >=2, "Less than 2 candidates");
        require(approved_candidates_count >=2, "Less than 2 approved candidates");
        require(votingProcess == false && _voteMinutes > 0, "Voting in Progress");
        startTime = block.timestamp;
        endTime = block.timestamp + _voteMinutes*60;
        votingProcess = true;
    }

    function stopVote() public onlyAdmin {
        require(block.timestamp >= endTime && votingProcess,"Current time should be greater than Election End time");
        votingProcess = false;
        gift_claimed = false;
        startTime = 0;
        endTime = 0;
        for (uint i=1; i<= candidatesCount ; i++) {
            addressmap[candidates[i].candidate_address] = 0;
            candidates[i].id = 0;
            candidates[i].candidate_address = address(0);
            candidates[i].name = '';
            candidates[i].voteCount = 0;
            candidates[i].approved = false;
            candidates[i].image_addr = '';
        }
        for (uint i=1; i<= votersCount ; i++) {
            voters[votersmap[i]] = false;
            votersmap[i] = address(0);
        }
        candidatesCount = 0;
        approved_candidates_count = 0;
        votersCount = 0;
    }

    function vote (uint _candidateId) public votingPeriod{
        // require that they haven't voted before
        require(!voters[msg.sender],"User already casted their vote");

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount && candidates[_candidateId].approved == true);

        // record that voter has voted
        voters[msg.sender] = true;
        votersCount++;
        votersmap[votersCount] = msg.sender;
        // update candidate vote Count
        candidates[_candidateId].voteCount ++;
        // trigger voted event
        emit votedEvent(_candidateId);
    }

    function claim_gift(uint _candidateId) public payable sufficientBalance {
        require(candidates[_candidateId].approved, "User not a Candidate");
        require(block.timestamp >= endTime && votingProcess, "Voting not started");
        require(!gift_claimed, "Already Gift Claimed");
        require(candidates[_candidateId].candidate_address == msg.sender, "Gift can be claimed by winner");
        address payable candidate_addr = payable(candidates[_candidateId].candidate_address);
        candidate_addr.transfer(1 ether);
        gift_claimed = true;
    }
}