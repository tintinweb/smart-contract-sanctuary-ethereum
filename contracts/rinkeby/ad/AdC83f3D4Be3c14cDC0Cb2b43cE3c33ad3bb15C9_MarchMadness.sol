pragma solidity ^0.5.0;

import "./ByteBracket.sol";
import "./FederatedOracleBytes8.sol";

/**
 * @title March Madness bracket pool smart contract
 *
 * The contract has four phases: submission, tournament, scoring, then the contest is over. During
 * the submission phase, entrants submit a cryptographic commitment to their bracket picks. Each
 * address may only make one submission. Entrants may reveal their brackets at any time after making
 * the commitment. Once the tournament starts, no further submissions are allowed. When the
 * tournament ends, the results are submitted by the oracles and the scoring period begins. During
 * the scoring period, entrants may reveal their bracket picks and score their brackets. The highest
 * scoring bracket revealed is recorded. After the scoring period ends, all entrants with a highest
 * scoring bracket split the pot and may withdraw their winnings.
 *
 * In the event that the oracles do not submit results or fail to reach consensus after a certain
 * amount of time, entry fees will be returned to entrants.
 */
contract MarchMadness {
    struct Submission {
        bytes32 commitment;
        bytes8 bracket;
        uint8 score;
        bool collectedWinnings;
        bool collectedEntryFee;
    }

    event SubmissionAccepted(address account);
    event NewWinner(address winner, uint8 score);
    event TournamentOver();

    FederatedOracleBytes8 resultsOracle;

	mapping(address => Submission) submissions;

    // Amount that winners will collect
    uint public winnings;

    // Number of submissions with a winning score
    uint public numWinners;

    // Data derived from results used by bracket scoring algorithm
    uint64 private scoringMask;

    // Fee in wei required to enter a bracket
    uint public entryFee;

    // Duration in seconds of the scoring phase
    uint public scoringDuration;

    // Timestamp of the start of the tournament phase
    uint public tournamentStartTime;

    // In case the oracles fail to submit the results or reach consensus, the amount of time after
    // the tournament has started after which to return entry fees to users.
    uint public noContestTime;

    // Timestamp of the end of the scoring phase
    uint public contestOverTime;

    // Byte bracket representation of the tournament results
    bytes8 public results;

    // The highest score of a bracket scored so far
    uint8 public winningScore;

    // The maximum allowed number of submissions
    uint32 public maxSubmissions;

    // The number of brackets submitted so far
    uint32 public numSubmissions;

    // IPFS hash of JSON file containing tournament information (eg. teams, regions, etc)
    string public tournamentDataIPFSHash;

	constructor(
        uint entryFee_,
        uint tournamentStartTime_,
        uint noContestTime_,
        uint scoringDuration_,
        uint32 maxSubmissions_,
        string memory tournamentDataIPFSHash_,
        address oracleAddress
    )
        public
    {
		entryFee = entryFee_;
        tournamentStartTime = tournamentStartTime_;
        scoringDuration = scoringDuration_;
        noContestTime = noContestTime_;
        maxSubmissions = maxSubmissions_;
        tournamentDataIPFSHash = tournamentDataIPFSHash_;
        resultsOracle = FederatedOracleBytes8(oracleAddress);
	}

    function submitBracket(bytes32 commitment) public payable {
        require(msg.value == entryFee);
        require(now < tournamentStartTime);
        require(numSubmissions < maxSubmissions);

        Submission storage submission = submissions[msg.sender];
        require(submission.commitment == 0);

        submission.commitment = commitment;
        numSubmissions++;
        emit SubmissionAccepted(msg.sender);
    }

    function startScoring() public {
        require(results == 0);
        require(now >= tournamentStartTime);
        require(now < noContestTime);

        bytes8 oracleValue = resultsOracle.finalValue();
        require(oracleValue != 0);

        results = oracleValue;
        scoringMask = ByteBracket.getScoringMask(results);
        contestOverTime = now + scoringDuration;
        emit TournamentOver();
    }

    function revealBracket(bytes8 bracket, bytes16 salt) public {
        Submission storage submission = submissions[msg.sender];
        bytes32 commitment = keccak256(abi.encodePacked(msg.sender, bracket, salt));
        require(commitment == submission.commitment);

        submission.bracket = bracket;
    }

    function scoreBracket(address account) public {
        require(results != 0);
        require(now < contestOverTime);

        Submission storage submission = submissions[account];
        require(submission.bracket != 0);
        require(submission.score == 0);

        submission.score = ByteBracket.getBracketScore(submission.bracket, results, scoringMask);

        if (submission.score > winningScore) {
            winningScore = submission.score;
            numWinners = 0;
        }
        if (submission.score == winningScore) {
            numWinners++;
            winnings = address(this).balance / numWinners;
            emit NewWinner(account, submission.score);
        }
    }

    function collectWinnings() public {
        require(now >= contestOverTime);

        Submission storage submission = submissions[msg.sender];
        require(submission.score == winningScore);
        require(!submission.collectedWinnings);

        submission.collectedWinnings = true;
        assert(msg.sender.send(winnings));
    }

    function collectEntryFee() public {
        require(now >= noContestTime);
        require(results == 0);

        Submission storage submission = submissions[msg.sender];
        require(submission.commitment != 0);
        require(!submission.collectedEntryFee);

        submission.collectedEntryFee = true;
        assert(msg.sender.send(entryFee));
    }

    function getBracketScore(bytes8 bracket) public view returns (uint8) {
        require(results != 0);

        return ByteBracket.getBracketScore(bracket, results, scoringMask);
    }

    function getBracket(address account) public view returns (bytes8) {
        return submissions[account].bracket;
    }

    function getScore(address account) public view returns (uint8) {
        return submissions[account].score;
    }

    function getCommitment(address account) public view returns (bytes32) {
        return submissions[account].commitment;
    }

    function hasCollectedWinnings(address account) public view returns (bool) {
        return submissions[account].collectedWinnings;
    }
}

pragma solidity ^0.5.0;

/// @title Oracle contract where m of n predetermined voters determine a value
contract FederatedOracleBytes8 {
    struct Voter {
        // Whether this account is a registered voter.
        bool isVoter;

        // Whether this account's vote has been counted.
        bool hasVoted;

        // IPFS hash of PGP signed proof of voter identity.
        string identityIPFSHash;
    }

    event VoterAdded(address account);
    event VoteSubmitted(address account, bytes8 value);
    event ValueFinalized(bytes8 value);

    mapping(address => Voter) public voters;
    mapping(bytes8 => uint8) public votes;

    uint8 public m;
    uint8 public n;
    bytes8 public finalValue;

    uint8 private voterCount;
    address private creator;

    constructor(uint8 m_, uint8 n_) public {
        creator = msg.sender;
        m = m_;
        n = n_;
    }

    function addVoter(address account, string calldata identityIPFSHash) external {
        require(msg.sender == creator);
        require(voterCount < n);

        Voter storage voter = voters[account];
        require(!voter.isVoter);

        voter.isVoter = true;
        voter.identityIPFSHash = identityIPFSHash;
        voterCount++;
        emit VoterAdded(account);
    }

    function submitValue(bytes8 value) public {
        Voter storage voter = voters[msg.sender];
        require(voter.isVoter);
        require(!voter.hasVoted);

        voter.hasVoted = true;
        votes[value]++;
        emit VoteSubmitted(msg.sender, value);

        if (votes[value] == m) {
            finalValue = value;
            emit ValueFinalized(value);
        }
    }
}

pragma solidity ^0.5.0;

// This library can be used to score byte brackets. Byte brackets are a succinct encoding of a
// 64 team bracket into an 8-byte array. The tournament results are encoded in the same format and
// compared against the bracket picks. To reduce the computation time of scoring a bracket, a 64-bit
// value called the "scoring mask" is first computed once for a particular result set and used to
// score all brackets.
//
// Algorithm description: https://drive.google.com/file/d/0BxHbbgrucCx2N1MxcnA1ZE1WQW8/view
// Reference implementation: https://gist.github.com/pursuingpareto/b15f1197d96b1a2bbc48
library ByteBracket {
    function getBracketScore(bytes8 bracket, bytes8 results, uint64 filter)
        public
        pure
        returns (uint8 points)
    {
        uint8 roundNum = 0;
        uint8 numGames = 32;
        uint64 blacklist = (uint64(1) << numGames) - 1;
        uint64 overlap = uint64(~(bracket ^ results));

        while (numGames > 0) {
            uint64 scores = overlap & blacklist;
            points += popcount(scores) << roundNum;
            blacklist = pairwiseOr(scores & filter);
            overlap >>= numGames;
            filter >>= numGames;
            numGames /= 2;
            roundNum++;
        }
    }

    function getScoringMask(bytes8 results)
        public
        pure
        returns (uint64 mask)
    {
        // Filter for the second most significant bit since MSB is ignored.
        bytes8 bitSelector = 0x4000000000000000;
        for (uint i = 0; i < 31; i++) {
            mask <<= 2;
            if (results & bitSelector != 0) {
                mask |= 1;
            } else {
                mask |= 2;
            }
            results <<= 1;
        }
    }

    // Returns a bitstring of half the length by taking bits two at a time and ORing them.
    //
    // Separates the even and odd bits by repeatedly
    // shuffling smaller segments of a bitstring.
    function pairwiseOr(uint64 bits) internal pure returns (uint64) {
        uint64 tmp;
        tmp = (bits ^ (bits >> 1)) & 0x22222222;
        bits ^= (tmp ^ (tmp << 1));
        tmp = (bits ^ (bits >> 2)) & 0x0c0c0c0c;
        bits ^= (tmp ^ (tmp << 2));
        tmp = (bits ^ (bits >> 4)) & 0x00f000f0;
        bits ^= (tmp ^ (tmp << 4));
        tmp = (bits ^ (bits >> 8)) & 0x0000ff00;
        bits ^= (tmp ^ (tmp << 8));
        uint64 evens = bits >> 16;
        uint64 odds = bits % 0x10000;
        return evens | odds;
    }

    // Counts the number of 1s in a bitstring.
    function popcount(uint64 bits) internal pure returns (uint8) {
        bits -= (bits >> 1) & 0x5555555555555555;
        bits = (bits & 0x3333333333333333) + ((bits >> 2) & 0x3333333333333333);
        bits = (bits + (bits >> 4)) & 0x0f0f0f0f0f0f0f0f;
        return uint8(((bits * 0x0101010101010101) & 0xffffffffffffffff) >> 56);
    }
}