/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
질문하고 답변하는 질의응답 게시판을 만드세요.
게시판은 번호, 제목, 질문 내용, 질의자, 현재 상태 그리고 답변 내용과 답변자로 이루어져 있습니다.

상태는 질문 등록, 취소, 답변 등록중, 완료가 있다.

모든 유저는 질문자도 답변자도 될 수 있다.
질의응답 과정은 평범하다.
질문자가 질문을 등록한 후에, 답변자가 답변을 다는 것이다.
단 질문자는 스스로의 질문에 답할 수 없다. 

질문자가 등록하면 질문 등록 상태가 된다.
복수의 답변자들이 한 질문에 답변을 등록할 수 있고,
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

+) 해당 시스템의 지속가능성을 위해 질문, 답변시 요구되는 금액을 수정하시오. */




contract QABoard{
// //게시판은 번호, 제목, 질문 내용, 질의자, 현재 상태 그리고 답변 내용과 답변자로 이루어져 있습니다.
//     struct QA{
//         string title;
//         string question;
//         address questioner;
//         uint state;
//         string answer;
//         address answerer;
//     }


//     mapping(address => QA) QAmapping;
   
//     // function registQuestion() public {
//     //     QAmapping[msg.sender] = QA(msg.sender,)

//     // }

//     function setQuestion(string _title, string _question, string _questioner) 


// // 상태는 질문 등록, 취소, 답변 등록중, 완료가 있다.
//     function getStateofQA(uint _a) public view returns(string memory) {
//         // 등록
//         if(_a = 0) {
//             return "질문 등록";
//         } else if (_a = 1) {
//             return "질문 취소"; 
//         } else if (_a = 2) {
//             return "답변 등록중"; 
//         } else (_a = 3) {
//             return "완료"; 
//         }
//     }

 }