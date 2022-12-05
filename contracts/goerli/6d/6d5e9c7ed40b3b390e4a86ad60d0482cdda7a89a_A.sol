/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract A {
//     // 상태는 질문 등록, 취소, 답변 등록중, 완료가 있다.
//     enum Status{register, isCancel, onGoing, isComplete}


//     // 질문하고 답변하는 질의응답 게시판을 만드세요. 게시판은 번호, 제목, 질문 내용, 질의자, 현재 상태 그리고 답변 내용과 답변자로 이루어져 있습니다.
//     struct board {
//         uint num;
//         string title;
//         string content;
//         // Status boardStatus;
//         address qBy;
//         address repBy;
//     }
    

//     modifier question(uint _amount) {
//         require(msg.sender.balance > 210000000000000000, "Not enough balance!");
//         require(_amount == 200000000000000000, "0.2ETH needed to register the question!");
//         payable(msg.sender).transfer(_amount);
//         _;
//     }
    
//     modifier reply(uint _amount) {
//         require(msg.sender.balance > 110000000000000000, "Not enough balance!");
//         require(_amount == 100000000000000000, "0.1ETH needed to reply the question!");
//         payable(msg.sender).transfer(_amount);
//         _;
//     }
//     mapping (address => board) BoardList;
//     board[] Board;
//     mapping (address => Status) StatusList;

//     // 질문자가 등록하면 질문 등록 상태가 된다.
//     // 복수의 답변자들이 한 질문에 답변을 등록할 수 있고 1개의 답변이라도 등록되면 그때부터 답변 등록중 상태가 된다.
//     // 그 중 질문자가 원하는 답변을 채택하면 완료 상태가 된다. 답변자는 한 질문에 대해 답변은 1개만 등록할 수 있다.
//     uint number = 1;
//     // function registerQ(string memory _title, string memory _content, uint _amt) public question(_amt) payable {
//     //     BoardList[msg.sender] = Board(number++, _title, _content, address(msg.sender), address(msg.sender));
//     // }

//     function cancelQ(address _adr) internal returns(uint) {
//         require(BoardList[msg.sender].qBy==msg.sender, "Only who questioned can cancel the according question.");
//         BoardList[_adr].pop();
//         return BoardList[_adr].num;
//     }

//     // // 단 질문자는 스스로의 질문에 답할 수 없다. 
//     // function replyQ() internal reply {
//     //     if ()
//     // }
}