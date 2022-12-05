/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract QandA {
    uint indexQ;
    enum Status {
        registered,
        canceled,
        ongoing,
        done
    }
    struct QBoard {
        uint number;
        string title;
        string q_content;
        address questioner;
        Status status;
        address[] selectedAnswer;
    }

    mapping(string => Answer[]) answersMapArray;
    mapping(string => Answer) answerMapping;
    struct Answer {
        address answerer;
        string answer;
    }

    mapping(string => QBoard) QBoards;
    mapping(address => uint) points;

    function Question(string memory _title, string memory _q_content) public payable {
        require(msg.value == 0.2 ether); //200000000000000000
        QBoards[_title].number = indexQ++;
        QBoards[_title].title = _title;
        QBoards[_title].q_content = _q_content;
        QBoards[_title].questioner = msg.sender;
        QBoards[_title].status = Status.registered;
    }
    function GetQuestion(string memory _title) public view returns(uint, string memory, string memory, address, Status, address[] memory ){
        return (QBoards[_title].number, QBoards[_title].title, QBoards[_title].q_content, QBoards[_title].questioner, QBoards[_title].status, QBoards[_title].selectedAnswer);
    }
    function GetAnswers(string memory _title) public view returns(Answer[] memory){
        return answersMapArray[_title];
    }
    function DeleteQuestion(string memory _title) public {
        require(msg.sender == QBoards[_title].questioner);
        require(QBoards[_title].status == Status.registered);
        QBoards[_title].status = Status.canceled;
    }

    function SetAnswer(string memory _title, string memory _answer) public payable{
        require(msg.value == 0.1 ether); //100000000000000000
        require(msg.sender != QBoards[_title].questioner);
        // require(keccak256(abi.encodePacked(answerMapping[_title].answer)) == keccak256(abi.encodePacked("")));
        require(msg.sender != answerMapping[_title].answerer);

        Answer memory tempAnswer;
        tempAnswer.answerer = msg.sender;
        tempAnswer.answer = _answer;
        answersMapArray[_title].push(tempAnswer);

        answerMapping[_title].answer = _answer;
        answerMapping[_title].answerer = msg.sender;

    }
    function SelectAnswer(string memory _title, address payable _answerer) public {
        require(msg.sender == QBoards[_title].questioner);
        QBoards[_title].selectedAnswer.push(_answerer);
        QBoards[_title].status = Status.done;
        _answerer.transfer(0.125 ether);
    }

    function FillPoint() public payable{
        points[msg.sender] += msg.value;
    }
    function getPoint() public view returns(uint){
        return points[msg.sender];
    }

}