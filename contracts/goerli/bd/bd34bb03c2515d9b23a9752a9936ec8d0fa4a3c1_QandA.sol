/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT
// 개인적으로 문제를 읽고 이해하는데 시간이 많이 소요됩니다.
// "다음날 수업전 까지 제출" 이런 옵션도 있으면 좋겠습니다.

pragma solidity >=0.7.0 <0.9.0;

contract QandA {
    enum Status {question, cancel, answering, done}

    struct QBoard {
        uint number;
        string title;
        address questioner;
        string answer;
        Status status;
    }
    struct Respondent {
        string name;
        string content;
    }

    uint index = 0;
    mapping(address => Respondent) Respondents;
    mapping(string => QBoard) Qboards;

    function question(string memory _title) public payable {
        require(msg.value == 200000000000000000);
        Qboards[_title] = QBoard(index++, _title, address(msg.sender), "", Status.question);
    }
    function cancel(string memory _title) public {
        require(Qboards[_title].status == Status.answering);
        Qboards[_title].status = Status.cancel;
    }
    function getQuestion(string memory _title) public view returns(string memory) {
        return Qboards[_title].answer;
    }
    function answer(string memory _title, string memory _answer) public payable{
        require(msg.value == 100000000000000000);
        Qboards[_title].answer = _answer;
        Qboards[_title].status = Status.done;
    }
}