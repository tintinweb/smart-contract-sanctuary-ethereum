/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
//20221205

// 추가 문제 못 했고, 
// 그 중 질문자가 원하는 답변을 채택하면 완료 상태가 된다. 
// 답변자는 한 질문에 대해 답변은 1개만 등록할 수 있다.
// 돈이 충분치 않으면 충전기능을 이용해야한다. 
// 답변 채택은 오직 질문자만 가능하고 여러개의 답변을 채택할 수 있다. 
// 질문자가 스스로 질문에 대한 답변이 필요없다고 느껴지면 취소할 수 있다. 
// 하지만, 본인의 질문에 답변이 이미 달려있는 상태라면 취소할 수 없다.
// 이정도 못했습니다. 

contract A {

    struct question {
        uint number;
        string title;
        string content;
        address writer;
        Status status;
        string [] answer;
        address [] answerer;
    }

    mapping (string => question) questions;

    struct user {
        string name; 
        address useradd;
        string [] qtitles;
        string [] qcontent;
        string [] atitles;
        string [] acontent;
    }

    // mapping(question => address) answerers; 이게 안 되다늬...
    uint index;
    enum Status{registered, cancelled, answering, completed}

    mapping (address => user) users;

    function resUser (string memory _n) public {
        users[msg.sender] = user(_n, msg.sender, new string [](0), new string [](0), new string [](0), new string [](0));
    }

    function regQ (string memory _tt, string memory _con) public payable {
        require (msg.value >= 2**18);
        questions[_tt] = question(index++, _tt, _con, msg.sender, Status.registered, new string[](0), new address[](0));
        users[msg.sender].qtitles.push(_tt);
        users[msg.sender].qcontent.push(_con);
    }

    function regAns (string memory _tt, string memory _answer) public payable {
        require (msg.value >= 1**18 && msg.sender != questions[_tt].writer);
        // && msg.sender != questions[_tt].answerer 배열에 없다는 것을 어떻게 쓰더라...
        questions[_tt].status = Status.answering;
        questions[_tt].answer.push(_answer);
        questions[_tt].answerer.push(msg.sender);
        users[msg.sender].atitles.push(_tt);
        users[msg.sender].acontent.push(_answer);
    }

    function getQ (string memory _tt) public view returns (uint, string memory, string memory, address, Status, string [] memory, address [] memory) {
        return (questions[_tt].number, questions[_tt].title, questions[_tt].content, questions[_tt].writer, questions[_tt].status, questions[_tt].answer, questions[_tt].answerer);
    }

    function getMyInfo () public view returns (string memory, address, string [] memory, string [] memory, string [] memory, string [] memory) {
        return (users[msg.sender].name, users[msg.sender].useradd, users[msg.sender].qtitles, users[msg.sender].qcontent, users[msg.sender].atitles, users[msg.sender].acontent);
    }

}