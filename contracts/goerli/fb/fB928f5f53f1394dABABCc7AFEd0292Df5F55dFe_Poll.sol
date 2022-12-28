// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Poll {
    struct CustomQuestions {
        uint256 endTime;
        string name;
        string[] question;
        uint256[] votes;
        address[] users;
    }

    mapping(string => CustomQuestions) private _QuestionMap;

    constructor() {}

    //Internal Functions
    function checkUserExists(string memory id, address user)
        internal
        view
        returns (bool)
    {
        // _QuestionMap[id].users
        for (uint256 i = 0; i < _QuestionMap[id].users.length; i++) {
            if (_QuestionMap[id].users[i] == user) {
                return true;
            }
        }
        return false;
    }

    //Adding Questions
    function addQuestions(
        string memory id,
        string[] memory questions,
        uint256 endTime,
        string memory name
    ) public {
        CustomQuestions storage temp = _QuestionMap[id];

        temp.endTime = endTime;
        string[] memory tempQuestions;
        uint256[] memory tempVotes;
        address[] memory tempUsers;
        temp.question = tempQuestions;
        temp.votes = tempVotes;
        for (uint256 i = 0; i < questions.length; i++) {
            temp.question.push(questions[i]);
            temp.votes.push(0);
        }
        temp.users = tempUsers;
        temp.name = name;
    }

    //Voting
    function vote(string memory id, uint256 questionId) public {
        require(
            block.timestamp < (_QuestionMap[id].endTime / 1000),
            "Time had Ended!"
        );
        require(!checkUserExists(id, msg.sender), "User Already Exists!");

        _QuestionMap[id].votes[questionId] += 1;
        _QuestionMap[id].users.push(msg.sender);
    }

    //Result of the Poll
    function result(string memory id) public view returns (uint256) {
        require(checkUserExists(id, msg.sender), "Vote to See the Result!");

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

    function getEndTime(string memory id) public view returns (uint256) {
        return _QuestionMap[id].endTime;
    }

    function getUsers(string memory id) public view returns (address[] memory) {
        return _QuestionMap[id].users;
    }

    function getName(string memory id) public view returns (string memory) {
        return _QuestionMap[id].name;
    }
}