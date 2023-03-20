// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Voting {
    string public init;
    address public owner;
    mapping(address => bool) public voters;
    mapping(address => bool) public admins;
    mapping(string => Campaign) public campaigns;
    string[] public campaignIds;
    string[] public candidateIds;
    mapping (address => uint) public nonces;


    struct Candidate {
        bool exists;
        uint256 votes;
        mapping(address => bool) votedBy;
    }

    struct Campaign {
        uint256 startTime;
        uint256 endTime;
        bool isPublic;
        uint256 minCandidatesPerVoter;
        uint256 maxCandidatesPerVoter;
        mapping(string => Candidate) candidates;
        string[] candidateIds;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the admin can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only the admin can call this function.");
        _;
    }

    modifier onlyVoter() {
        require(voters[msg.sender], "Only registered voters can call this function.");
        _;
    }

    constructor(string memory _init) {
        owner = msg.sender;
        init = _init;
    }

    function createCampaign(string memory campaignId, uint256 startTime, uint256 endTime, bool isPublic, uint256 minCandidatesPerVoter, uint256 maxCandidatesPerVoter, string[] calldata _candidateIds) external onlyAdmin {
        require(startTime < endTime, "Start time must be before end time.");
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.startTime == 0, "Campaign with the same ID already exists.");
        campaign.startTime = startTime;
        campaign.endTime = endTime;
        campaign.isPublic = isPublic;
        campaign.minCandidatesPerVoter = minCandidatesPerVoter;
        campaign.maxCandidatesPerVoter = maxCandidatesPerVoter;
        for (uint256 i = 0; i < _candidateIds.length; i++) {
            campaign.candidates[_candidateIds[i]].exists = true;
            campaign.candidateIds.push(_candidateIds[i]);
        }
        campaignIds.push(campaignId);
    }

    function addCandidate(string memory campaignId, string memory candidateId) external onlyAdmin {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.startTime == 0, "Campaign does not exist.");
        require(campaign.candidates[candidateId].exists == false, "Candidate already exists in campaign.");
        campaign.candidates[candidateId].exists = true;
    }

    function removeCandidate(string memory campaignId, string memory candidateId) external onlyAdmin {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.startTime == 0, "Campaign does not exist.");
        require(campaign.candidates[candidateId].exists == true, "Candidate does not exist in campaign.");
        delete campaign.candidates[candidateId];
    }

    function addAdmin(address adminAddress) external onlyOwner {
        admins[adminAddress] = true;
    }

    function addVoter(address voterAddress) external onlyAdmin {
        // require(!campaigns[campaignId].isPublic, "Campaign is public.");
        voters[voterAddress] = true;
    }

    function removeVoter(address voterAddress) external onlyAdmin {
        require(voters[voterAddress], "Voter is not registered.");
        delete voters[voterAddress];
    }

    function vote(string memory campaignId, string[] calldata _candidateIds) external onlyVoter {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.startTime > 0, "Campaign does not exist.");
        require(!campaign.isPublic, "Campaign is private.");
        require(block.timestamp >= campaign.startTime && block.timestamp <= campaign.endTime, "Campaign is not active.");
        require(_candidateIds.length >= campaign.minCandidatesPerVoter && _candidateIds.length <= campaign.maxCandidatesPerVoter, "Invalid number of candidates selected.");
        for (uint256 i = 0; i < _candidateIds.length; i++) {
            Candidate storage candidate = campaign.candidates[_candidateIds[i]];
            require(candidate.exists == true, "Candidate does not exist in campaign.");
            require(candidate.votedBy[msg.sender] == false, "Voter already voted for candidate.");
            candidate.votes++;
            candidate.votedBy[msg.sender] = true;
        }
    }

    // function vote_public(string memory campaignId, string[] calldata _candidateIds) external {
    //     Campaign storage campaign = campaigns[campaignId];
    //     require(campaign.startTime > 0, "Campaign does not exist.");
    //     require(block.timestamp >= campaign.startTime && block.timestamp <= campaign.endTime, "Campaign is not active.");
    //     require(_candidateIds.length >= campaign.minCandidatesPerVoter && _candidateIds.length <= campaign.maxCandidatesPerVoter, "Invalid number of candidates selected.");
    //     for (uint256 i = 0; i < _candidateIds.length; i++) {
    //         Candidate storage candidate = campaign.candidates[_candidateIds[i]];
    //         require(candidate.exists == true, "Candidate does not exist in campaign.");
    //         require(candidate.votedBy[msg.sender] == false, "Voter already voted for candidate.");
    //         candidate.votes++;
    //         candidate.votedBy[msg.sender] = true;
    //     }
    // }


    function getCandidatesList(string memory campaignId) external view returns (string[] memory) {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.startTime > 0, "Campaign does not exist.");
        return campaign.candidateIds;
    }

    function getNumberOfCandidates(string memory campaignId) internal view returns (uint256) {
        Campaign storage campaign = campaigns[campaignId];
        uint256 count = 0;
        for (uint256 i = 0; i < candidateIds.length; i++) {
            string memory candidateId = candidateIds[i];
            if (campaign.candidates[candidateId].exists) {
                count++;
            }
        }
        return count;
    }

    function getVotes(string memory campaignId, string[] calldata _candidateIds) external view returns (uint256[] memory) {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.startTime > 0, "Campaign does not exist.");
        uint256[] memory voteCounts = new uint256[](_candidateIds.length);
        for (uint256 i = 0; i < _candidateIds.length; i++) {
            Candidate storage candidate = campaign.candidates[_candidateIds[i]];
            require(candidate.exists == true, "Candidate does not exist in campaign.");
            voteCounts[i] = candidate.votes;
        }
        return voteCounts;
    }
}