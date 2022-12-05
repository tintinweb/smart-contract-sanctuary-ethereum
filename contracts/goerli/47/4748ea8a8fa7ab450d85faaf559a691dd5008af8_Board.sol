/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract Board{

/*
    //번호, 제목, 질문 내용, 질의자, 현재 상태 그리고 답변 내용과 답변자
    struct questionList{
        uint number;  
        string title; 
        string question;
        address questioner;

        string[] receivedList; //내가 받은 답안 목록
    }

    mapping(string => questionList) questions; 

    struct replyList{
        string reply;
        address replier;     
    }

    //질문 등록, 취소, 답변 등록중, 완료
    enum Status{ask, cancel, replying, solved} //0,1,2,3
    Status public status;


        //질문자가 등록하면 질문 등록 상태가 된다. 
        //복수의 답변자들이 한 질문에 답변을 등록할 수 있고 
        //1개의 답변이라도 등록되면 그때부터 답변 등록중 상태가 된다. 
        //그 중 질문자가 원하는 답변을 채택하면 완료 상태가 된다. 답변자는 한 질문에 대해 답변은 1개만 등록할 수 있다.
        function setQuestion(string memory _title, string memory _question) public{
            questions[_title] =
            questions[msg.sender].questionList.push(_title);
        }


        //충전기능 (1. 컨트랙트 -> 회원의 지갑,  2. 회원의 지갑 -> 컨트랙트)
        function Charge(address payable _to, uint _amount) public payable{
        _to.transfer(_amount); 
        }
   

        //질문할 때, 회원지갑->컨트랙트 0.2eth 전송 
        function Ask() public payable{ 

        }

        //답변할 때, 회원지갑->컨트랙트 0.1eth 전송
        function Reply() public payable{

        }


        //컨트랙트-> 회원지갑으로 0.125eth 전송 (답변이 채택되면 0.125eth를 돌려받는다.)
        function Adopt(address payable _to) public payable{
            
            //답변 채택은 오직 질문자만 가능하고 여러개의 답변을 채택할 수 있다.
            questioner = msg.sender;

            _to.transfer(0.125eth); 
        }
*/
}