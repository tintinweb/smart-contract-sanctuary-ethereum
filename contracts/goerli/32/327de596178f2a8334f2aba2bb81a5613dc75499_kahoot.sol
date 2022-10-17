/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract kahoot {
  address payable public owner;
  string private nameOfGame;

  constructor(string memory _gameName) {
    owner = payable(msg.sender);
    nameOfGame = _gameName;
  }

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  function deposit() public payable {
    owner.transfer(msg.value);
  }

  struct Questions {
    string[] Answers;
    uint256 correctAnswer;
  }
  struct Students {
    string Name;
    address StudentAddress;
  }
  address[] studentsArray;

  mapping(uint256 => mapping(string => address)) public students;
  mapping(uint256 => address) public studentsAddresses;
  mapping(address => uint256) public studentsIds;
  mapping(uint256 => mapping(string => Questions)) public questions;
  mapping(uint256 => string) public idQuestions;
  mapping(uint256 => string[]) public questionAnswers;
  mapping(uint256 => uint256) public correctAnswerMapping;
  mapping(address => uint256[]) public didStudentRespond;

  // Add a student to be allowed to play the game
  function addStudent(
    uint256 _id,
    address _studentAddress,
    string memory _studentName
  ) public isOwner {
    students[_id][_studentName] = _studentAddress;
    studentsAddresses[_id] = _studentAddress;
    studentsIds[_studentAddress] = _id;
    studentsArray.push(_studentAddress);
  }

  // Adds question/answers to mappings
  function addQuestion(
    uint256 _qid,
    string memory _question,
    string memory _answerOne,
    string memory _answerTwo,
    string memory _answerThree,
    string memory _answerFour,
    uint256 _correctAnswer
  ) public isOwner {
    Questions storage _q = questions[_qid][_question];
    _q.Answers = [_answerOne, _answerTwo, _answerThree, _answerFour];
    _q.correctAnswer = _correctAnswer;
    idQuestions[_qid] = _question;
    questionAnswers[_qid] = [_answerOne, _answerTwo, _answerThree, _answerFour];
    correctAnswerMapping[_qid] = _correctAnswer;
  }

  // Fetches Question String By It's ID in the 2nd Mapping
  function fetchQuestion(uint256 _qid) public view returns (string memory) {
    string memory veribeel;
    veribeel = idQuestions[_qid];
    return veribeel;
  }

  // Fetches All possible Answers of a certain question by ID
  function fetchAnswers(uint256 _id) public view returns (string[] memory) {
    string memory veribeel;
    string[] memory allAnswers;
    veribeel = idQuestions[_id];
    allAnswers = questionAnswers[_id];
    return allAnswers;
  }

  // Returns True/False based on string input if matches QuestionID's correctAnswer
  function answerQuestion(uint256 _id, uint256 _studentAnswer)
    public
    returns (bool)
  {
    uint256 studentAnswer = correctAnswerMapping[_id];
    didStudentRespond[msg.sender] = [_id];
    if (_studentAnswer == studentAnswer) {
      return true;
    } else {
      return false;
    }
  }

  function isThisAddressStudent(address _studentAddress)
    public
    view
    returns (bool)
  {
    for (uint256 i = 0; i < studentsArray.length; i++) {
      if (studentsArray[i] == _studentAddress) {
        return true;
      }
    }
    return false;
  }

  function questionsAnsweredByStudent(address _address)
    public
    view
    returns (uint256[] memory)
  {
    uint256[] memory variable = didStudentRespond[_address];
    return variable;
  }

}