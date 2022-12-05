/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract EXAM{

    enum status{
        register,
        cancel,
        registering,
        done
    }

    struct board{
        uint num;
        string title;
        string contents;
        address questionPerson;
        status stat;
        mapping(address=>string) answer;
        mapping(address=>string) answerPerson;
    }



    mapping(uint=>board) boards;
    uint[] boardNum;
    mapping(address=>uint[]) boardMapping;

    uint index;
    //게시판 등록
    function registerQuestion(string memory title,string memory contents)public payable{
        require(msg.value == 10**17*2);
        index++;
        // require(_num);
        boards[index].num=index;
        boards[index].title=title;
        boards[index].questionPerson = msg.sender;
        boards[index].stat = status.register;

        boardNum.push(index);
        boardMapping[msg.sender].push(index);
    }
    //올라와 있는 질문 번호 보기 함수
    function showQuestions()public returns(uint[] memory){
        return boardNum;
    }
    //번호를 검색해서 질문 내용 확인
    // function searchQuestion(uint _num)public view returns(string memory){
        
    // }
    //번호와 함께 답변 접근.
    function answer(uint _num,string memory contents)public payable{
        require(msg.value == 10**17);
        require(msg.sender!=boards[_num].questionPerson);
        require(bytes(boards[_num].answerPerson[msg.sender]).length<1);

        boards[_num].answerPerson[msg.sender]=contents;
        boards[_num].stat = status.registering;
    }
    //질문자가 자신의 질문 번호를 확인
    function ShowmyQuestionNum()public view returns(uint[] memory){
        return boardMapping[msg.sender];
    }
    //번호를 기반으로 취소를 위해 자신이 질문한 게시글에 접근.
    function cancel(uint _num)public{
        require(boards[_num].stat!=status.registering);
    }


}