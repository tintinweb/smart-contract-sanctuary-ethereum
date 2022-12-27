// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Poll {
    struct CustomQuestions {
        uint256 endTime;
        string[] question;
        uint256[] votes;
    }

    mapping(string => CustomQuestions) private _QuestionMap;

    constructor() {}

    //Adding Questions
    function addQuestions(
        string memory id,
        string[] memory questions,
        uint256 endTime
    ) public {
        CustomQuestions storage temp = _QuestionMap[id];

        temp.endTime = endTime;
        for (uint256 i = 0; i < questions.length; i++) {
            temp.question.push(questions[i]);
            temp.votes.push(0);
        }
    }

    //Voting
    function vote(string memory id, uint256 questionId) public {
        require(
            block.timestamp < (_QuestionMap[id].endTime / 1000),
            "Time had Ended!"
        );
        _QuestionMap[id].votes[questionId] += 1;
    }

    //Result of the Poll
    function result(string memory id) public view returns (uint256) {
        uint256 tempI = 0;

        for (uint256 i = 0; i < _QuestionMap[id].votes.length; i++) {
            if (_QuestionMap[id].votes[i] > _QuestionMap[id].votes[tempI]) {
                tempI = i;
            }
        }

        return tempI;
    }

    //Get Details
    function getQuestions(string memory id)
        public
        view
        returns (string[] memory)
    {
        return _QuestionMap[id].question;
    }

    function getQuestion(string memory id, uint256 index)
        public
        view
        returns (string memory)
    {
        return _QuestionMap[id].question[index];
    }

    function getVotes(string memory id) public view returns (uint256[] memory) {
        return _QuestionMap[id].votes;
    }

    function getVote(string memory id, uint256 index)
        public
        view
        returns (uint256)
    {
        return _QuestionMap[id].votes[index];
    }
}