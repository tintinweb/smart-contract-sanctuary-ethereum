/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
// 20221205
pragma solidity 0.8.14;

contract Board_1205 {
    enum Status { register_question, cancel, answering, done }

    struct Board {
        uint num;
        string title;
        string content;
        address questioner;
        Status status;
        mapping (address => string) answerList;
        address [] selectedAnswerList;
    }

    mapping (string => Board) BoardList;
    uint index;

    struct User {
        string name;
        address addr;
        uint point;
    }
    mapping (address => User) UserList;

    function setUser(string memory _name) public {
        UserList[msg.sender] = User(_name, msg.sender, 0);
    }

    /* 
    1 eth = 100 point
    질문 : -20point 
    답변 : -10point 
    채택 : +5point 
    */

    function setQuestion(string memory _title, string memory _content) public {
        require(UserList[msg.sender].point > 20);
        BoardList[_title].num = index++;
        BoardList[_title].title = _title;
        BoardList[_title].content = _content;
        BoardList[_title].questioner = msg.sender;
        BoardList[_title].status = Status.register_question;

        // 포인트 지불
        UserList[msg.sender].point -= 20;
    }

    // 답변하기
    function answer(string memory _title, string memory _content) public {
        // 질문자는 스스로의 질문에 답할 수 없다. 
        require(BoardList[_title].questioner != msg.sender);
        // 질문 등록 상태 확인
        require(BoardList[_title].status == Status.register_question);
        // 답변 포인트 있는지 확인
        require(UserList[msg.sender].point > 20);

        // 답변 등록하기
        BoardList[_title].answerList[msg.sender] = _content;

        // 답변 포인트 지불
        UserList[msg.sender].point -= 10;

        // 1개의 답변이라도 등록되면 그때부터 답변 등록중 상태
        BoardList[_title].status = Status.answering;
    }

    // 답변 채택하기
    function chooseAnswer(string memory _title, address _answerer) public {
        // 질문한 사람이 채택
        require(BoardList[_title].questioner == msg.sender);

        // 채택하기
        BoardList[_title].selectedAnswerList.push(_answerer);
        // 채택 포인트 추가
        UserList[msg.sender].point += 5;
        
        // 질문자가 원하는 답변을 채택하면 완료 상태
        BoardList[_title].status = Status.done;
    }

    // 질문 취소하기

    // 포인트 충전하기 (1eth 당 100point)
    function chargeUpPoints() public payable {
        require(msg.value >= (10 ** 18)); // 최소 1이더

        uint amount;
        
        if(msg.value >= (10 ** 19)) { // 10이더 이상 충전하면

        }

        amount = msg.value / (10 ** 16);
        UserList[msg.sender].point += amount;
    }
}