// SPDX-License-Identifier: UNLICENSED
// Made by @kryptopaul

pragma solidity ^0.8.17;

contract AskOnChain {

    uint totalQuestions;
    uint totalAnswers;
    mapping (address => string) public usernames;
    mapping (address => Question[]) public questions;
    
    struct Question {
        uint id;
        string question;
        string answer;
    }

    event NewQuestion(address indexed from, address indexed to, uint id, string question);
    event NewAnswer(address indexed by, uint id, string answer);

    constructor() {
        totalQuestions = 0;
    }    

    function setUsername(string memory _username) public {
        usernames[msg.sender] = _username;
    }

    function submitQuestion(address _to ,string memory _question) public {
        uint id = questions[_to].length;
        questions[_to].push(Question(id, _question, ""));
        emit NewQuestion(msg.sender, _to, id, _question);
        totalQuestions++;

    }

    function answerQuestion(uint _id, string memory _answer) public {
        Question storage question = questions[msg.sender][_id];
        question.answer = _answer;
        emit NewAnswer(msg.sender, _id, _answer);
    }
}