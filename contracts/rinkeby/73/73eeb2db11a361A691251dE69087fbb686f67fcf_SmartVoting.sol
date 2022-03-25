//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SmartVoting {
    struct Vote {
        address candidate;
        address voter;
    }

    struct Voting {
        uint256 id;
        string title;
        uint256 endTime;
        bool finished;
        uint256 rewardSum;
        bool rewardPaid;
        address winner;
        address[] candidates;
        Vote[] votes;
        mapping(address => address[]) candidateVotes;
        mapping(address => bool) voters;
    }

    struct VotingStats {
        uint256 id;
        string title;
        uint256 endTime;
        bool finished;
        uint256 rewardSum;
        bool rewardPaid;
        address[] candidates;
        address winner;
        Vote[] votes;
    }

    event VotingAdded(
        uint256 id,
        string title,
        uint256 endTime,
        address[] candidates
    );

    event VotingFinished(
        uint256 id,
        string title,
        uint256 endTime,
        address winner
    );

    event VoteAdded(uint256 id, address voter, address candidate);

    address private owner;
    uint256 private currentId;
    uint256 private availableCommission;

    mapping(uint256 => Voting) private votings;

    /// Only the owner can call this function.
    error NotOwner();

    /// Voting does not exist.
    error VotingDoesNotExist();

    /// This voting already finished.
    error VoteAlreadyFinished();

    /// Candidate does not exist.
    error CandidateDoesNotExist();

    /// This vote already counted at voting.
    error VoteAlreadyCounted();

    /// Correct bid is 0.01 ETH.
    error IncorrectBid();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier votingExists(uint256 _votingId) {
        if (votings[_votingId].endTime == 0) revert VotingDoesNotExist();
        _;
    }

    modifier votingIsActive(uint256 _votingId) {
        if (votings[_votingId].finished) revert VoteAlreadyFinished();
        _;
    }

    modifier candidateExists(uint256 _votingId, address _candidate) {
        bool found = false;
        for (uint256 i = 0; i < votings[_votingId].candidates.length; i++) {
            if (votings[_votingId].candidates[i] == _candidate) {
                found = true;
                break;
            }
        }
        if (!found) revert CandidateDoesNotExist();
        _;
    }

    modifier canWithdrawReward(uint256 _votingId) {
        require(votings[_votingId].finished, "Voting hasn't ended yet.");

        require(!votings[_votingId].rewardPaid, "Reward already paid.");

        require(
            address(votings[_votingId].winner) == msg.sender,
            "Only the winner can withdraw reward."
        );

        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addVoting(
        uint256 _duration,
        string memory _title,
        address[] memory _candidates
    ) public onlyOwner {
        require(
            keccak256(abi.encodePacked(_title)) !=
                keccak256(abi.encodePacked("")),
            "Voting title is required."
        );

        require(_candidates.length > 0, "Candidates are required.");

        uint256 endTime = block.timestamp + _duration;
        Voting storage v = votings[currentId];
        v.id = currentId;
        v.title = _title;
        v.endTime = endTime;
        v.finished = false;
        v.candidates = _candidates;

        emit VotingAdded(currentId, _title, endTime, _candidates);

        currentId++;
    }

    function getVotings() public view returns (VotingStats[] memory) {
        VotingStats[] memory res = new VotingStats[](currentId);
        for (uint256 i = 0; i < currentId; i++) {
            res[i] = VotingStats({
                id: votings[i].id,
                title: votings[i].title,
                endTime: votings[i].endTime,
                finished: votings[i].finished,
                rewardSum: votings[i].rewardSum,
                rewardPaid: votings[i].rewardPaid,
                winner: votings[i].winner,
                candidates: votings[i].candidates,
                votes: votings[i].votes
            });
        }
        return res;
    }

    function getVoting(uint256 _votingId)
        public
        view
        votingExists(_votingId)
        returns (VotingStats memory)
    {
        return
            VotingStats({
                id: votings[_votingId].id,
                title: votings[_votingId].title,
                endTime: votings[_votingId].endTime,
                finished: votings[_votingId].finished,
                rewardSum: votings[_votingId].rewardSum,
                rewardPaid: votings[_votingId].rewardPaid,
                winner: votings[_votingId].winner,
                candidates: votings[_votingId].candidates,
                votes: votings[_votingId].votes
            });
    }

    function finishVoting(uint256 _votingId)
        public
        votingExists(_votingId)
        votingIsActive(_votingId)
    {
        require(
            votings[_votingId].endTime <= block.timestamp,
            "Voting hasn't ended yet."
        );

        address currentCandidate = votings[_votingId].candidates[0];
        uint256 maxVotes = votings[_votingId]
            .candidateVotes[currentCandidate]
            .length;
        uint256 num = 1;
        for (uint256 i = 1; i < votings[_votingId].candidates.length; i++) {
            currentCandidate = votings[_votingId].candidates[i];
            if (
                votings[_votingId].candidateVotes[currentCandidate].length >
                maxVotes
            ) {
                maxVotes = votings[_votingId]
                    .candidateVotes[currentCandidate]
                    .length;
                num = 1;
            } else if (
                votings[_votingId].candidateVotes[currentCandidate].length ==
                maxVotes
            ) {
                num++;
            }
        }

        address[] memory leaders = new address[](num);
        uint256 pos = 0;
        for (uint256 i = 0; i < votings[_votingId].candidates.length; i++) {
            currentCandidate = votings[_votingId].candidates[i];
            if (
                votings[_votingId].candidateVotes[currentCandidate].length ==
                maxVotes
            ) {
                leaders[pos] = currentCandidate;
                pos++;
            }
        }

        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % leaders.length;

        votings[_votingId].winner = leaders[randomIndex];
        votings[_votingId].finished = true;

        emit VotingFinished(
            _votingId,
            votings[_votingId].title,
            block.timestamp,
            votings[_votingId].winner
        );
    }

    function addVote(uint256 _votingId, address _candidate)
        public
        payable
        votingExists(_votingId)
        votingIsActive(_votingId)
        candidateExists(_votingId, _candidate)
    {
        if (msg.value != 10000000000000000 wei) revert IncorrectBid();

        if (votings[_votingId].voters[msg.sender]) revert VoteAlreadyCounted();

        votings[_votingId].voters[msg.sender] = true;
        votings[_votingId].votes.push(
            Vote({candidate: _candidate, voter: msg.sender})
        );
        votings[_votingId].candidateVotes[_candidate].push(msg.sender);
        votings[_votingId].rewardSum += msg.value;

        emit VoteAdded(_votingId, msg.sender, _candidate);
    }

    function withdrawReward(uint256 _votingId)
        public
        votingExists(_votingId)
        canWithdrawReward(_votingId)
    {
        uint256 commission = 10 * (votings[_votingId].rewardSum / 100);
        uint256 amount = votings[_votingId].rewardSum - commission;

        availableCommission += commission;
        votings[_votingId].rewardPaid = true;

        payable(msg.sender).transfer(amount);
    }

    function getCommission() public view onlyOwner returns (uint256) {
        return availableCommission;
    }

    function withdrawCommission()
        public
        onlyOwner
    {
        uint256 amount = availableCommission;
        availableCommission = 0;

        payable(msg.sender).transfer(amount);
    }
}