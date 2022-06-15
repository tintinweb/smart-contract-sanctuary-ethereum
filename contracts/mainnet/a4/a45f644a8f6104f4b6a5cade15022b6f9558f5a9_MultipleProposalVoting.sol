// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;
import "./Strings.sol";
import "./Context.sol";

contract MultipleProposalVoting is Context {
    mapping(string => uint256)[] public votes;
    string[][] public possibleAnswers;
    uint256 public totalVotes;
    uint256 public maxVotes;
    mapping(address => bool) public voters;

    event VoteOccurred(address voter, uint256 voteCount);

    /**
     * @dev Creates a survey by specifying possible answers for each question. Each element in the
     * outer array corresponds to a question. The inner array includes possible answers to that question.
     * While answers are stored on-chain, the questions are not.
     */
    constructor(string[][] memory possibleAnswers_, uint256 maxVotes_) {
        possibleAnswers = possibleAnswers_;
        for (uint64 i = 0; i < possibleAnswers_.length; ++i) {
            votes.push();
        }
        totalVotes = 0;
        maxVotes = maxVotes_;
    }

    /**
     * @dev Votes for answers to all the questions posed function for buys on a whitelist. The price can be different from
     *  the regular minting function. In addition,
     */
    function vote(uint64[] memory answers) public {
        require(
            answers.length == possibleAnswers.length,
            string.concat(
                "Number of answers (",
                Strings.toString(answers.length),
                ") doesn't match number of questions (",
                Strings.toString(possibleAnswers.length),
                ")."
            )
        );
        totalVotes++;
        require(totalVotes <= maxVotes, "Too many votes have been cast.");
        require(!voters[_msgSender()], "Address has already voted.");
        voters[_msgSender()] = true;
        for (uint64 i = 0; i < answers.length; ++i) {
            require(
                answers[i] < possibleAnswers[i].length,
                string.concat(
                    "Answer number ",
                    Strings.toString(i),
                    " is ",
                    Strings.toString(answers[i]),
                    " which is out of bounds - [0, ",
                    Strings.toString(possibleAnswers[i].length),
                    ")."
                )
            );
            votes[i][possibleAnswers[i][answers[i]]]++;
        }

        emit VoteOccurred(_msgSender(), totalVotes);
    }
}