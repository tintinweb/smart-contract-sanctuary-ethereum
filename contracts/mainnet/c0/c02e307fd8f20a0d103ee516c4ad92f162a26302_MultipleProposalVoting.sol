// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;
import "./AccessControlEnumerable.sol";

contract MultipleProposalVoting is AccessControlEnumerable {
    bytes32 public constant PAYOUT_ROLE = keccak256("PAYOUT_ROLE");

    /** @dev A count of votes voted by users. The first index is question and the second index is possible answers.  */
    uint256[][] public votes;
    /** @dev The maximum number of answers for each question. numAnswers.length will equal votes.length.  */
    uint64[] public maxNumAnswers;
    /** @dev The total number of votes cast.  */
    uint256 public totalVotes;
    /** @dev The maximum number of votes that can be cast.  */
    uint256 public maxVotes;
    /** @dev The cost of each extra vote after the first one in wei.  */
    uint256 public extraVoteCost;
    /** @dev The number of times each person has voted. */
    mapping(address => uint256) public voters;

    event VoteOccurred(
        address voter,
        uint64[] answers,
        uint256 numVotes,
        uint256 voteCount,
        string clientInfo
    );

    /**
     * @dev Creates a survey by specifying the nunber of answers for each question and the
     * maximum number of votes that are castable as well as the cost of votes beyond the first
     * one.
     */
    constructor(
        uint64[] memory maxNumAnswers_,
        uint256 maxVotes_,
        uint256 extraVoteCost_
    ) {
        maxNumAnswers = maxNumAnswers_;
        for (uint64 i = 0; i < maxNumAnswers_.length; ++i) {
            votes.push();
            for (uint64 j = 0; j < maxNumAnswers_[i]; ++j) {
                votes[i].push();
            }
        }
        totalVotes = 0;
        maxVotes = maxVotes_;
        extraVoteCost = extraVoteCost_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Votes for answers to the questions created in the constructor.
     */
    function vote(
        uint64[] memory answers,
        uint256 numVotes,
        string memory clientInfo
    ) public payable {
        require(numVotes > 0, "Must vote once.");
        require(
            answers.length == maxNumAnswers.length,
            "Number of answers doesn't match number of questions."
        );
        totalVotes += numVotes;
        require(totalVotes <= maxVotes, "Too many votes have been cast.");

        uint256 voteCost = computeCost(numVotes);
        require(voteCost == msg.value, "Incorrect payment.");

        voters[_msgSender()] += numVotes;

        for (uint64 i = 0; i < answers.length; ++i) {
            require(0 <= answers[i], "Answer is out of bounds.");
            require(answers[i] < maxNumAnswers[i], "Answer is out of bounds.");
            votes[i][answers[i]] += numVotes;
        }

        emit VoteOccurred(
            _msgSender(),
            answers,
            numVotes,
            totalVotes,
            clientInfo
        );
    }

    /**
     * @dev Adds old voters from previous contracts to this one.
     */
    function adminAddVoters(address[] memory oldVoters)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint64[] memory nullVotes;
        for (uint256 i = 0; i < oldVoters.length; ++i) {
            address oldVoter = oldVoters[i];
            voters[oldVoter] += 1;
            totalVotes += 1;
            require(totalVotes <= maxVotes, "Too many votes have been cast.");
            emit VoteOccurred(oldVoter, nullVotes, 1, totalVotes, "oldVoter");
        }
    }

    /**
     * @dev Withdraw ETH from this contract to an account in `PAYOUT_ROLL`.
     */
    function withdraw() public onlyRole(PAYOUT_ROLE) {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Send failed.");
    }

    function computeCost(uint256 numVotes) internal view returns (uint256) {
        if (voters[_msgSender()] == 0) {
            return (numVotes - 1) * extraVoteCost;
        } else {
            return numVotes * extraVoteCost;
        }
    }
}