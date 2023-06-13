// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DecentralizedVoting {
    struct VotingInstance {
        uint256 id;
        string name;
        string organizationName;
        address creator;
        mapping(uint256 => Candidate) candidates;
        uint256 candidateCount;
        bool isOpen;
        mapping(address => bool) hasVoted;
        uint256 startTime;
        uint256 endTime;
        bool isVotingStarted;
    }

    struct Candidate {
        uint256 id;
        string name;
        string role;
        string description;
        uint256 voteCount;
    }

    struct VotingInstanceDetails {
        uint256 id;
        string name;
        string organizationName;
        address creator;
        uint256 candidateCount;
        bool isOpen;
    }

    uint256 public instanceId;
    mapping(uint256 => VotingInstance) public instances;
    address public admin;

    event VotingInstanceCreated(uint256 id, string name, address creator);
    event CandidateAdded(
        uint256 instanceId,
        uint256 candidateId,
        string candidateName,
        string candidateRole,
        string candidateDescription
    );
    event VoteCasted(uint256 instanceId, uint256 candidateId, address voter);

    constructor() {
        admin = msg.sender;
    }

    function createInstance(
        string memory _name,
        string memory _organizationName
    ) public {
        VotingInstance storage instance = instances[++instanceId];
        instance.id = instanceId;
        instance.name = _name;
        instance.organizationName = _organizationName;
        instance.creator = msg.sender;
        instance.isOpen = false;
        emit VotingInstanceCreated(instanceId, _name, msg.sender);
    }

    function closeInstance(uint256 _instanceId) public {
        require(_instanceId <= instanceId, "Invalid instance ID");
        VotingInstance storage instance = instances[_instanceId];
        require(
            msg.sender == instance.creator,
            "Only the creator can close the instance"
        );

        instance.isOpen = false;
        instance.endTime = block.timestamp;
    }

    function addCandidate(
        uint256 _instanceId,
        string memory _candidateName,
        string memory _candidateRole,
        string memory _candidateDescription
    ) public {
        require(_instanceId <= instanceId, "Invalid instance ID");
        VotingInstance storage instance = instances[_instanceId];
        require(
            msg.sender == instance.creator,
            "Only the creator can add candidates"
        );
        require(
            !instance.isVotingStarted,
            "Cannot add candidates after voting has started"
        );

        uint256 candidateId = instance.candidateCount + 1;
        instance.candidates[candidateId] = Candidate({
            id: candidateId,
            name: _candidateName,
            role: _candidateRole,
            description: _candidateDescription,
            voteCount: 0
        });
        instance.candidateCount++;
        emit CandidateAdded(
            _instanceId,
            candidateId,
            _candidateName,
            _candidateRole,
            _candidateDescription
        );
    }

    function startVoting(uint256 _instanceId, uint256 _duration) public {
        require(_instanceId <= instanceId, "Invalid instance ID");
        VotingInstance storage instance = instances[_instanceId];
        require(
            msg.sender == instance.creator,
            "Only the creator can start voting"
        );
        require(
            !instance.isVotingStarted,
            "Voting has already started for this instance"
        );

        instance.startTime = block.timestamp;
        instance.endTime = instance.startTime + _duration;
        require(block.timestamp < instance.endTime, "Voting has already ended");

        instance.isVotingStarted = true;
        instance.isOpen = true;
    }

    function vote(uint256 _instanceId, uint256 _candidateId) public {
        require(_instanceId <= instanceId, "Invalid instance ID");
        VotingInstance storage instance = instances[_instanceId];

        // Update isOpen flag
        if (block.timestamp >= instance.endTime) {
            instance.isOpen = false;
        }

        require(
            instance.isVotingStarted && instance.isOpen,
            "Voting has not started for this instance or instance is closed"
        );
        require(
            !instance.hasVoted[msg.sender],
            "You have already voted in this instance"
        );

        Candidate storage candidate = instance.candidates[_candidateId];
        require(candidate.id > 0, "Invalid candidate ID");

        candidate.voteCount++;
        instance.hasVoted[msg.sender] = true;
        emit VoteCasted(_instanceId, _candidateId, msg.sender);
    }

    function getCandidateVotes(
        uint256 _instanceId,
        uint256 _candidateId
    ) public view returns (uint256) {
        require(_instanceId <= instanceId, "Invalid instance ID");
        VotingInstance storage instance = instances[_instanceId];
        require(
            _candidateId <= instance.candidateCount,
            "Invalid candidate ID"
        );

        return instance.candidates[_candidateId].voteCount;
    }

    function getCandidateCount(
        uint256 _instanceId
    ) public view returns (uint256) {
        require(_instanceId <= instanceId, "Invalid instance ID");
        VotingInstance storage instance = instances[_instanceId];
        return instance.candidateCount;
    }

    function getOverallResults(
        uint256 _instanceId
    )
        public
        view
        returns (
            uint256[] memory,
            string[] memory,
            string[] memory,
            uint256[] memory
        )
    {
        require(_instanceId <= instanceId, "Invalid instance ID");
        VotingInstance storage instance = instances[_instanceId];
        uint256[] memory candidateIds = new uint256[](instance.candidateCount);
        string[] memory candidateNames = new string[](instance.candidateCount);
        string[] memory candidateRoles = new string[](instance.candidateCount);
        uint256[] memory voteCounts = new uint256[](instance.candidateCount);

        for (uint256 i = 0; i < instance.candidateCount; i++) {
            uint256 candidateId = i + 1;
            candidateIds[i] = candidateId;
            candidateNames[i] = instance.candidates[candidateId].name;
            candidateRoles[i] = instance.candidates[candidateId].role;
            voteCounts[i] = instance.candidates[candidateId].voteCount;
        }

        return (candidateIds, candidateNames, candidateRoles, voteCounts);
    }

    function getCandidate(
        uint256 _instanceId,
        uint256 _candidateId
    )
        public
        view
        returns (uint256, string memory, string memory, string memory, uint256)
    {
        require(_instanceId <= instanceId, "Invalid instance ID");
        VotingInstance storage instance = instances[_instanceId];
        require(
            _candidateId <= instance.candidateCount,
            "Invalid candidate ID"
        );
        Candidate storage candidate = instance.candidates[_candidateId];
        return (
            candidate.id,
            candidate.name,
            candidate.role,
            candidate.description,
            candidate.voteCount
        );
    }

    function getCandidates(
        uint256 _instanceId
    ) public view returns (Candidate[] memory) {
        require(_instanceId <= instanceId, "Invalid instance ID");
        VotingInstance storage instance = instances[_instanceId];

        Candidate[] memory candidates = new Candidate[](
            instance.candidateCount
        );

        for (uint256 i = 0; i < instance.candidateCount; i++) {
            uint256 candidateId = i + 1;
            candidates[i] = instance.candidates[candidateId];
        }

        return candidates;
    }

    function getInstanceStatus(
        uint256 _instanceId
    ) public view returns (bool isOpen, bool hasStarted, bool hasEnded) {
        require(_instanceId <= instanceId, "Invalid instance ID");
        VotingInstance storage instance = instances[_instanceId];
        isOpen = instance.isOpen;
        hasStarted = block.timestamp >= instance.startTime;
        hasEnded = block.timestamp >= instance.endTime;
    }

    function getAllInstances()
        public
        view
        returns (VotingInstanceDetails[] memory)
    {
        VotingInstanceDetails[]
            memory allInstances = new VotingInstanceDetails[](instanceId);

        for (uint256 i = 1; i <= instanceId; i++) {
            VotingInstance storage instance = instances[i];
            allInstances[i - 1] = VotingInstanceDetails({
                id: instance.id,
                name: instance.name,
                organizationName: instance.organizationName,
                creator: instance.creator,
                candidateCount: instance.candidateCount,
                isOpen: instance.isOpen
            });
        }

        return allInstances;
    }

    function deleteInstance(uint256 _instanceId) public {
        require(_instanceId <= instanceId, "Invalid instance ID");
        VotingInstance storage instance = instances[_instanceId];
        require(
            msg.sender == instance.creator,
            "Only the creator can delete the instance"
        );

        // Deleting the instance from the mapping
        delete instances[_instanceId];
    }
}