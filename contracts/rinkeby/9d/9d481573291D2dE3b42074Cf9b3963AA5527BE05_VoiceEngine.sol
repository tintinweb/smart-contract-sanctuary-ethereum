//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VoiceEngine {
    address public owner;
    uint256 constant DURATION = 3 days; // 3 * 24 * 60 * 60 = 259200 sec
    uint256 public constant FEE = 1e16; // wei
    uint256 constant TAX = 10; // 10%
    uint256 public availableBalance;

    struct Vote {
        address payable winner;
        mapping(address => Canditate) candidates;
        address[] allCandidates;
        mapping(address => bool) participants;
        uint256 participantsCounter;
        uint256 maxVotes;
        uint256 winnerBenefits;
        uint256 startAt;
        uint256 endAt;
        bool exist;
    }

    struct Canditate {
        bool registered;
        uint256 voiceCounter;
    }

    mapping(uint256 => Vote) public votes;

    event VoteCreated(uint256 voteIndex, address[] candidates, uint256 endAt);
    event NewVote(uint256 voteIndex, address candidate);
    event VoteFinished(
        address voteWinner,
        uint256 winnerVotes,
        uint256 winnerBenefits
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner(address _to) {
        require(msg.sender == owner, "You are not owner");
        require(_to != address(0), "Incorrect address");
        _;
    }

    function createVote(
        uint256 _voteIndex,
        address[] memory _canditates,
        uint256 _duration
    ) external onlyOwner(owner) {
        require(
            votes[_voteIndex].exist == false,
            "Vote with this index is existed"
        );
        require(_canditates.length != 0, "List of candidates are empty");
        require(
            _canditates.length > 1,
            "List of candidates have to contain at least 2 candidates"
        );

        for (uint256 i = 0; i < _canditates.length; i++) {
            require(
                votes[_voteIndex].candidates[_canditates[i]].registered != true,
                "List of candidates has duplicates"
            );
            votes[_voteIndex].candidates[_canditates[i]].registered = true;
            votes[_voteIndex].allCandidates.push(_canditates[i]);
        }

        uint256 duration = _duration == 0 ? DURATION : _duration;
        votes[_voteIndex].startAt = block.timestamp;
        votes[_voteIndex].endAt = votes[_voteIndex].startAt + duration;
        votes[_voteIndex].exist = true;

        emit VoteCreated(_voteIndex, _canditates, votes[_voteIndex].endAt);
    }

    function makeVoting(uint256 _voteIndex, address payable _candidateAddr)
        external
        payable
    {
        require(
            votes[_voteIndex].exist != false,
            "Vote with this index doesn't exist"
        );
        require(block.timestamp < votes[_voteIndex].endAt, "Vote is ended");
        require(msg.value >= FEE, "Not enough funds");
        require(
            votes[_voteIndex].candidates[_candidateAddr].registered,
            "Candidate with this address doesn't register"
        );
        require(msg.sender != _candidateAddr, "You can't vote for yourself");

        uint256 refund = msg.value - FEE;

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
            votes[_voteIndex].winnerBenefits += (msg.value - refund);
            availableBalance += ((msg.value - refund) * TAX) / 100;
        } else {
            votes[_voteIndex].winnerBenefits += msg.value;
            availableBalance += (msg.value * TAX) / 100;
        }

        require(
            votes[_voteIndex].participants[msg.sender] == false,
            "You can vote only one time"
        );
        votes[_voteIndex].candidates[_candidateAddr].voiceCounter++;
        votes[_voteIndex].participantsCounter++;
        votes[_voteIndex].participants[msg.sender] = true;

        if (
            votes[_voteIndex].candidates[_candidateAddr].voiceCounter >
            votes[_voteIndex].maxVotes
        ) {
            votes[_voteIndex].maxVotes = votes[_voteIndex]
                .candidates[_candidateAddr]
                .voiceCounter;
            votes[_voteIndex].winner = _candidateAddr;
        }

        emit NewVote(_voteIndex, _candidateAddr);
    }

    function taxWithdraw(uint256 amount, address payable _to)
        external
        onlyOwner(_to)
    {
        require(
            availableBalance >= amount,
            "Not enough funds on available balance"
        );
        _to.transfer(amount);
    }

    function finishVote(uint256 _voteIndex) external {
        require(
            block.timestamp > votes[_voteIndex].endAt &&
                votes[_voteIndex].exist,
            "This voting is not finished"
        );

        votes[_voteIndex].exist = false;

        uint256 benefits = votes[_voteIndex].winnerBenefits -
            ((votes[_voteIndex].winnerBenefits * TAX) / 100);
        payable(votes[_voteIndex].winner).transfer(benefits);

        emit VoteFinished(
            votes[_voteIndex].winner,
            votes[_voteIndex].maxVotes,
            benefits
        );
    }

    function getAllCandidates(uint256 _voteIndex)
        external
        view
        returns (address[] memory)
    {
        return votes[_voteIndex].allCandidates;
    }

    function getWinner(uint256 _voteIndex) external view returns (address) {
        return votes[_voteIndex].winner;
    }

    function getWinnerBenefits(uint256 _voteIndex)
        external
        view
        returns (uint256)
    {
        uint256 benefits = votes[_voteIndex].winnerBenefits -
            ((votes[_voteIndex].winnerBenefits * TAX) / 100);
        return benefits;
    }

    function getNumberOfParticipants(uint256 _voteIndex)
        external
        view
        returns (uint256)
    {
        return votes[_voteIndex].participantsCounter;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}