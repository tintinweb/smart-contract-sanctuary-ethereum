//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract VotingCon {
    address private owner;
    uint256 private votingCounter = 0;
    uint256 private candidatesCounter = 0;
    uint256 private voterCounter = 0;

    mapping(uint256 => VotingEntity) private idToVotingMap;
    mapping(uint256 => address) private idVotingToCreatorMap;

    mapping(uint256 => Candidate[]) private votingIdToCandidatesMap;
    mapping(uint256 => Candidate) private IdCandidateToCandidateMap;

    mapping(uint256 => Voter[]) private votingIdToVotersMap;
    mapping(uint256 => Voter) private voterIdToVoterMap;

    mapping(uint256 => uint256) private candidateAndPosition;

    enum TypeOfVoting {
        PUBLIC_VOTING,
        ANONYM_VOTING
    }

    enum StagesOfVoting {
        CREATED,
        STARTED,
        FINISHED
    }

    event DeployedOwnerEvent(address ownerAddress);
    event AddAnVotingEvent(address creator, string votingName, uint256 id);
    event RemoveVotingEvent(uint256 votingId);
    event AddCandidateEvent(uint256 votingId, string nameCandidate);
    event RemoveCandidateEvent(uint256 candidateId);

    event StartVotingEvent(
        StagesOfVoting stagesOfVoting,
        uint256 startTime,
        uint256 finishTime
    );

    event ToVoteEvent(
        uint256 candidateId,
        uint256 voterId,
        uint256 candidateVoteCounter
    );

    event RecalculationPositionsEvent(Candidate[] candidates);

    constructor() {
        owner = msg.sender;
        emit DeployedOwnerEvent(owner);
    }

    modifier onlyCreator(uint256 _id) {
        require(
            idVotingToCreatorMap[_id] == msg.sender,
            "Not a creator of this voting"
        );
        _;
    }

    modifier checkStagesOfVotingCREATED(uint256 _votingId) {
        require(
            idToVotingMap[_votingId].stagesOfVoting == StagesOfVoting.CREATED,
            "Voting has to be in stage CREATED"
        );
        _;
    }

    modifier checkStagesOfVotingSTARTED(uint256 _votingId) {
        require(
            idToVotingMap[_votingId].stagesOfVoting == StagesOfVoting.STARTED,
            "Voting has to be in stage STARTED"
        );
        _;
    }

    modifier checkEndTime(uint256 _votingId) {
        require(
            idToVotingMap[_votingId].finishVotingTime < block.timestamp,
            "Time of voting has been finished"
        );
        _;
    }

    struct VotingEntity {
        string name;
        uint256 id;
        TypeOfVoting votingType;
        StagesOfVoting stagesOfVoting;
        address owner;
        uint256 startVotingTime;
        uint256 finishVotingTime;
    }

    struct Candidate {
        string name;
        uint256 id;
        uint256 voteCounter;
        uint256 position;
    }

    struct Voter {
        address voterAddress;
        uint256 voterId;
        bool voted;
    }

    function createVoting(string memory _nameVoting, TypeOfVoting _votingType)
        public
        returns (uint256)
    {
        idVotingToCreatorMap[votingCounter] = msg.sender;
        idToVotingMap[votingCounter] = VotingEntity(
            _nameVoting,
            votingCounter,
            _votingType,
            StagesOfVoting.CREATED,
            msg.sender,
            0,
            0
        );

        emit AddAnVotingEvent(msg.sender, _nameVoting, votingCounter);
        return votingCounter++;
    }

    function addCandidate(uint256 _votingId, string memory _nameCandidate)
        public
        onlyCreator(_votingId)
        checkStagesOfVotingCREATED(_votingId)
        returns (uint256)
    {
        checkDuplicatesCandidates(
            votingIdToCandidatesMap[_votingId],
            _nameCandidate
        );

        Candidate storage candidateEntity = votingIdToCandidatesMap[_votingId][candidatesCounter];
        candidateEntity.name = _nameCandidate;
        candidateEntity.id = candidatesCounter;
        candidateEntity.position = 0;
        candidateEntity.voteCounter = 0;
        
        votingIdToCandidatesMap[_votingId][candidatesCounter] = candidateEntity;
        emit AddCandidateEvent(_votingId, _nameCandidate);
        return candidatesCounter++;
    }

    function checkDuplicatesCandidates(
        Candidate[] memory _candidates,
        string memory nameCandidate
    ) private pure {
        uint256 amountOfCandidates = _candidates.length;
        for (uint256 i = 0; i < amountOfCandidates; i++) {
            require(
                keccak256(abi.encodePacked((_candidates[i].name))) !=
                    keccak256(abi.encodePacked((nameCandidate))),
                "You can't add the same candidate twice"
            );
        }
    }

    function removeCandidate(uint256 _votingId, uint256 _candidateId)
        public
        onlyCreator(_votingId)
        checkStagesOfVotingCREATED(_votingId)
    {
        delete votingIdToCandidatesMap[_votingId][_candidateId];
        delete IdCandidateToCandidateMap[_candidateId];
        emit RemoveCandidateEvent(_candidateId);
    }

    function startVoting(uint256 _votingId, uint256 finishTime)
        public
        onlyCreator(_votingId)
        checkStagesOfVotingCREATED(_votingId)
    {
        idToVotingMap[_votingId].stagesOfVoting = StagesOfVoting.STARTED;
        idToVotingMap[_votingId].startVotingTime = block.timestamp;
        idToVotingMap[_votingId].finishVotingTime =
            block.timestamp +
            finishTime;
        emit StartVotingEvent(
            StagesOfVoting.STARTED,
            idToVotingMap[_votingId].startVotingTime,
            idToVotingMap[_votingId].finishVotingTime
        );
    }

    function toVote(uint256 _votingId, uint256 _candidateId)
        public
        checkStagesOfVotingSTARTED(_votingId)
        checkEndTime(_votingId)
        returns (Candidate[] memory, uint256)
    {
        votingIdToVotersMap[_votingId][voterCounter] = Voter(
            msg.sender,
            voterCounter,
            true
        );
        voterIdToVoterMap[voterCounter] = Voter(msg.sender, voterCounter, true);
        IdCandidateToCandidateMap[_candidateId].voteCounter += 1;
        Candidate[] memory candidates = recalculatePosition(_votingId);
        emit ToVoteEvent(
            _candidateId,
            voterCounter,
            IdCandidateToCandidateMap[_candidateId].voteCounter
        );
        voterCounter++;
        return (candidates, voterCounter - 1);
    }

    function recalculatePosition(uint256 _votingId)
        private
        returns (Candidate[] memory)
    {
        Candidate[] memory candidates = votingIdToCandidatesMap[_votingId];

        for (uint256 i = 0; i < candidates.length; i++) {
            for (uint256 j = i + 1; j < candidates.length; j++) {
                if (candidates[i].voteCounter < candidates[j].voteCounter) {
                    Candidate memory tempCandidate = candidates[i];
                    candidates[i] = candidates[j];
                    candidates[j] = tempCandidate;
                }
            }
        }

        candidates[0].position = 1;
        uint256 tempPosition = 1;
        for (uint256 i = 1; i < candidates.length; i++) {
            if (candidates[i].voteCounter == candidates[i - 1].voteCounter) {
                candidates[i].position = tempPosition;
            } else {
                tempPosition++;
                candidates[i].position = tempPosition;
            }
        }

        emit RecalculationPositionsEvent(candidates);
        return candidates;
    }

    function finishVoting(uint256 _votingId)
        public
        checkStagesOfVotingSTARTED(_votingId)
        returns (Candidate[] memory)
    {
        idToVotingMap[_votingId].stagesOfVoting = StagesOfVoting.FINISHED;
        return recalculatePosition(_votingId);
    }

    function removeVoting(uint256 _votingId)
        public
        checkStagesOfVotingCREATED(_votingId)
    {
        delete idToVotingMap[_votingId];
        delete idVotingToCreatorMap[_votingId];
        emit RemoveVotingEvent(_votingId);
    }
}