/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.7;

enum PollState {
    NOT_STARTED, // 0-value for uninitialized polls
    OPEN,
    CLOSED
}

/**
 * Part of ERC20 token interface.
 */
interface IToken {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

struct Poll {
    string question;
    string[] options;
    address owner;
    IToken token;

    PollState state;

    mapping(address => bool) hasVoted;
    mapping(address => uint) votes;
    mapping(address => uint) voteWeights;
    address[] voted;
}

struct PollOptionResult {
    /// Total weight of all votes for an option
    uint score;
    /// Addresess of all users who voted for the option
    address[] voters;
    /// Weights of all votes for the option
    /// voteWeight[x] corresponds to weight of vote of voters[x]
    uint[] voteWeights;
}

/**
 * ERC20 token balance weighted voting contract.
 *
 * This contract allows for any user to start a poll with any finite number of possible choices (options).
 * Any user can vote for any option but only for one.
 * The user that started the poll can close it at any moment.
 * When a poll is closed the contract will get and remember balances of all voted users.
 * Balance of a ERC20 token specified during poll creation is used.
 * After the poll is closed, anyone can access it's result.
 */
contract Voting {
    uint pollCount = 0;
    mapping(uint => Poll) polls;

    /**
     * Emitted when a poll is started
     *
     * @param owner owner of the poll
     * @param pollId identifier of the poll
     */
    event PollStarted(address indexed owner, uint pollId);

    /**
     * Emitted when a poll is closed
     *
     * @param owner owner of the poll
     * @param pollId identifier of the poll
     */
    event PollClosed(address indexed owner, uint pollId);

    /**
     * Start a poll with question "`question`" and possible answers `options`
     * using balance of ERC20 token `token` as vote weight
     *
     * @param question short question text
     * @param options array of possible answers
     * @param token address of ERC20 token contract used for determining weight of the votes
     */
    function startPoll(string memory question, string[] memory options, address token) public returns (uint) {
        uint pollId = pollCount;
        pollCount = pollCount + 1;

        Poll storage poll = polls[pollId];

        poll.question = question;
        poll.options = options;
        poll.owner = msg.sender;
        poll.token = IToken(token);
        poll.state = PollState.OPEN;

        emit PollStarted(msg.sender, pollId);

        return pollId;
    }

    modifier requirePollState(uint pollId, PollState state) {
        require(polls[pollId].state == state, "Illegal poll state");
        _;
    }

    /**
     * Vote for option `option` in poll #`pollId`
     *
     * @param pollId identifier of the poll
     * @param option index of the option to vote for
     */
    function vote(uint pollId, uint option) public requirePollState(pollId, PollState.OPEN) {
        Poll storage poll = polls[pollId];

        require(option < poll.options.length, "Illegal option index");

        if (!poll.hasVoted[msg.sender]) {
            poll.hasVoted[msg.sender] = true;
            poll.voted.push(msg.sender);
        }

        poll.votes[msg.sender] = option;
    }

    /**
     * Close poll #`pollId`
     *
     * @param pollId identifier of the poll to close
     */
    function close(uint pollId) public requirePollState(pollId, PollState.OPEN) {
        Poll storage poll = polls[pollId];

        require(msg.sender == poll.owner, "not an owner");

        for (uint i = 0; i < poll.voted.length; i++) {
            address voter = poll.voted[i];

            poll.voteWeights[voter] = poll.token.balanceOf(voter);
        }

        poll.state = PollState.CLOSED;

        emit PollClosed(poll.owner, pollId);
    }

    /**
     * Get question and answers for poll #`pollId`
     *
     * @param pollId identifier of the poll
     * @return question - text of the question, options - array of possible answers
     */
    function getQuestion(uint pollId) public view returns (string memory question, string[] memory options) {
        return (polls[pollId].question, polls[pollId].options);
    }

    /**
     * Get number of votes in poll #`pollId`
     *
     * @param pollId identifier of the poll
     * @return number of votes
     * @dev returns 0 for not started polls
     */
    function getVoteCount(uint pollId) public view returns (uint) {
        return polls[pollId].voted.length;
    }

    /**
     * Get results of a closed poll #`pollId`
     *
     * @param pollId identifier of the poll
     * @return results - detailed information about all votes in given poll
     * 
     * @dev results[x] corresponds to votes for x'th option of the poll
     */
    function getResult(uint pollId) public view requirePollState(pollId, PollState.CLOSED)
        returns (PollOptionResult[] memory results) {
        Poll storage poll = polls[pollId];

        results = new PollOptionResult[](poll.options.length);

        uint[] memory voterCounts = new uint[](poll.options.length);

        for (uint i = 0; i < poll.voted.length; i++) {
            voterCounts[poll.votes[poll.voted[i]]] += 1;
        }

        for (uint i = 0; i < poll.options.length; i++) {
            results[i].voters = new address[](voterCounts[i]);
            results[i].voteWeights = new uint[](voterCounts[i]);
            voterCounts[i] = 0;
        }

        for (uint i = 0; i < poll.voted.length; i++) {
            address voter = poll.voted[i];
            uint option = poll.votes[voter];
            uint weight = poll.voteWeights[voter];

            results[option].score += weight;
            results[option].voters[voterCounts[option]] = voter;
            results[option].voteWeights[voterCounts[option]] = weight;

            ++voterCounts[option];
        }
    }
}