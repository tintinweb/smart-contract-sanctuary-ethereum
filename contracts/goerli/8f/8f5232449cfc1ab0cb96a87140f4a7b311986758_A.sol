/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/*
221205
질문하고 답변하는 질의응답 게시판을 만드세요. 
게시판은 번호, 제목, 질문 내용, 질의자, 현재 상태 그리고 답변 내용과 답변자로 이루어져 있습니다.

상태는 질문 등록, 취소, 답변 등록중, 완료가 있다.

모든 유저는 질문자도 답변자도 될 수 있다. 질의응답 과정은 평범하다. 
질문자가 질문을 등록한 후에, 답변자가 답변을 다는 것이다. 
단 질문자는 스스로의 질문에 답할 수 없다. 

질문자가 등록하면 질문 등록 상태가 된다. 
복수의 답변자들이 한 질문에 답변을 등록할 수 있고 
1개의 답변이라도 등록되면 그때부터 답변 등록중 상태가 된다. 
그 중 질문자가 원하는 답변을 채택하면 완료 상태가 된다. 
답변자는 한 질문에 대해 답변은 1개만 등록할 수 있다.

질문할 때는 0.2eth가 답변할 때는 0.1eth가 요구된다. 
돈이 충분치 않으면 충전기능을 이용해야한다. 
답변이 채택되면 0.125eth를 돌려받는다. 
답변 채택은 오직 질문자만 가능하고 여러개의 답변을 채택할 수 있다. 

질문자가 스스로 질문에 대한 답변이 필요없다고 느껴지면 취소할 수 있다. 
하지만, 본인의 질문에 답변이 이미 달려있는 상태라면 취소할 수 없다. 

모든 유저들은 이 시스템에 있는 질의응답들의 각 현황을 검색하여 찾아볼 수 있어야 하고, 
또 자신이 한 질문이나 답변 역시 볼 수 있어야 한다. 

+) 1분동안 답변이 등록되지 않으면 자동으로 취소상태로 변경되게 하시오.

+) 10eth 이상 한번에 충전하면 금액의 10%를 보너스로 충전할 수 있게 하는 기능을 구현하시오.

+) 해당 시스템의 지속가능성을 위해 질문, 답변시 요구되는 금액을 수정하시오.
*/

contract A {

    enum Status {question, cancel, waiting, answer} 
    // 상태는 질문 등록, 취소, 답변 등록중, 완료

    struct Board {
        uint num; // 번호
        string title; // 제목
        string contents; // 질문 내용
        address name; // 질의자
        Status status; // 현재 상태
        string answer_contents; // 답변 내용
        address answer_name; // 답변자
    }
    mapping(string => Board) board;
    
    // 질문 등록
    function setQuestion(string memory _title) public payable {
        require(msg.value >= 2**18); // 최소 0.2이더를 넣어야 한다
        board[_title].status = Status.question;
    }
    
    // 질문에 답변
    function setAnswer (string memory _title) public payable{
        require(msg.value >= 1**18); // 최소 0.1이더를 넣어야 한다
        board[_title].status = Status.waiting;
    }

    // 답변 채택
    function setChoice (string memory _title) public payable{
        require(board[_title].name == msg.sender);
        board[_title].status = Status.answer;
    }

    // 등록된 질문 보기
    function getAnswer(string memory _title) public view returns(uint, string memory, string memory, address, Status, string memory, address) {
        return (board[_title].num, board[_title].title, board[_title].contents, board[_title].name, board[_title].status, board[_title].answer_contents, board[_title].answer_name);
    }

    // 질문 취소
    function setCancel(string memory _title) public {
        require(board[_title].name == msg.sender && board[_title].status != Status.answer);
        board[_title].status = Status.cancel;
    }
}