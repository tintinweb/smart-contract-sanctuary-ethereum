/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Community {
    // 상태 순서대로 질문 등록, 취소, 답변 등록중, 완료
    enum Status {registration, cancellation, registering, completion}

    struct board {
        uint number;
        string title;
        string question;
        address questioner;
        Status status;
        mapping (address => string) answer;
    }
    mapping (string => board) BoardList;

    modifier isNotQuestioner(string memory _title) {
        require(BoardList[_title].questioner != msg.sender);
        _;
    }

    modifier isQuestioner(string memory _title) {
        require(BoardList[_title].questioner == msg.sender);
        _;
    }

    // 질문 등록
    uint index=0;
    function setQuestion(string memory _title, string memory _question) public payable{
        require(0.2 ether == msg.value);

        BoardList[_title].number = ++index;
        BoardList[_title].title = _title;
        BoardList[_title].question = _question;
        BoardList[_title].questioner = msg.sender;
        BoardList[_title].status = Status.registration;
    }

    // 질문 답변
    function setAnswer(string memory _title, string memory _answer) public isNotQuestioner(_title) payable{
        require(0.1 ether == msg.value);
        require(keccak256(bytes(BoardList[_title].answer[msg.sender])) == keccak256(bytes("")), "It is already registered.");

        BoardList[_title].status = Status.registering;
        BoardList[_title].answer[msg.sender] = _answer;
    }

    // 답변 채택
    function adoption(string memory _title, address payable _addr) public isQuestioner(_title) {
        BoardList[_title].status = Status.registration;
        _addr.transfer(0.125 ether);
    }

    // 질문 취소
    function deleteQuestion(string memory _title) public isQuestioner(_title) {
        require(BoardList[_title].status == Status.registration, "It is already answer.");

        delete BoardList[_title];
    }

    // 충전 기능
    // 10eth 이상 한번에 충전하면 금액의 10%를 보너스로 충전할 수 있게 하는 기능을 구현하시오.
    function charging(uint _amount) public payable {
        payable(msg.sender).transfer(_amount);
    }

    // 현황 검색
    // function getBoard(string memory _title) public view returns(board memory) {
    //     return BoardList[_title];
    // }

    // 1분동안 답변 등록되지 않을 시 자동 취소 => block.timestamp 이용

    // 해당 시스템의 지속가능성을 위해 질문, 답변시 요구되는 금액을 수정하시오.
}