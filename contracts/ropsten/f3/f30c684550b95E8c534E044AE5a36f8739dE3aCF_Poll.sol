// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// The sender account has already voted, only one vote can be done per account.
error AlreadyVoted();
/// Invalid vote, this choice is not available. Expected 1 <= `possibilities`, got `choice`
/// @dev With Brownie, it is not yet possible to easily test custom errors with arguments
// error InvalidChoice(uint256 choice, uint256 possibilities);
error InvalidChoice();
/// This poll is already over, votes cannot be registered anymore
error VotesAreClosed();
/// This poll is already over, the current timestamp `currentTimestamp`
/// is > the end timestamp `endTimestamp`
// error VotingPeriodIsOver(uint256 currentTimestamp, uint256 endTimestamp);
error VotingPeriodIsOver();
/// This poll is not over yet, and the result cannot be finalized
error VotingPeriodIsNotOver();
/// Only the contract owner may call this function
error OnlyOwner();

/// @title Multi-option polls
/// @author MDR
/// @notice Deploy some simple polls which allow multiple options (and not just yes/no)
contract Poll {
    address public owner;
    uint256 public deadline;
    string public proposal;
    uint256 public nbChoices;
    State public state;
    mapping(address => uint256) public votes;
    uint256[] public scoreBoard;
    uint256 public finalChoice;

    enum State {
        ONGOING,
        CANCELLED,
        FINISHED
    }

    /// @notice Deploy a new poll
    /// @param _ownerAcc The address to consider as owner of the pool
    /// @param _deadline Timestamp after which votes will be rejected
    /// @param _proposalLink Arbitrary string to describe the poll. Usually an URL to a webpage with some details
    /// @param _nbChoices Number of choices the poll should have. What's behind each choice (eg. 1,2,3) should be detailed in the _proposalLink page
    constructor(
        address _ownerAcc,
        uint256 _deadline,
        string memory _proposalLink,
        uint256 _nbChoices
    ) {
        owner = _ownerAcc;
        deadline = _deadline;
        proposal = _proposalLink;
        state = State.ONGOING;
        // The possible choices for the vote are [1, ..., nbChoices]. 0 is "not yet voted"
        nbChoices = _nbChoices;

        // uint[] memory
        scoreBoard = new uint256[](nbChoices + 1);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    event UserVote(address voter, uint256 choice);

    function vote(uint256 choiceIdx) public {
        if (votes[msg.sender] != 0) {
            revert AlreadyVoted();
        }
        if (choiceIdx == 0 || choiceIdx > nbChoices) {
            revert InvalidChoice();
        }
        if (state != State.ONGOING) {
            revert VotesAreClosed();
        }

        if (block.timestamp > deadline) {
            revert VotingPeriodIsOver();
        }

        votes[msg.sender] = choiceIdx;
        scoreBoard[choiceIdx] += 1;
        emit UserVote(msg.sender, choiceIdx);
    }

    function cancel() public onlyOwner {
        if (block.timestamp > deadline) {
            revert VotingPeriodIsOver();
        }
        if (state != State.ONGOING) {
            revert VotesAreClosed();
        }

        state = State.CANCELLED;
    }

    // Anybody can finalize
    function finalize() public {
        if (state != State.ONGOING) {
            revert VotesAreClosed();
        }
        if (block.timestamp < deadline) {
            revert VotingPeriodIsNotOver();
        }

        uint256 maxVotes = 0;
        for (uint256 i = 0; i <= nbChoices; i++) {
            if (scoreBoard[i] > maxVotes) {
                finalChoice = i;
                maxVotes = scoreBoard[i];
            }
        }
        state = State.FINISHED;
    }
}