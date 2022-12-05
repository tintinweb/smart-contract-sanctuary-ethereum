/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;
contract Test {

    enum Status{signUp, cancel, enrolling, done}
    uint globalNum=1;

    struct Board {
        uint num;
        string title;
        string question;
        address registrant;
        Status now;
        mapping(address => Answer) answers;
        // Answer[] answers;
        uint aCount;
        //uint time;    //등록 시간
    }

    struct Answer {
        uint num;
        address answer;
        string detail;
        bool selected;
    }

    mapping(string => Board) questions;

    //질문 등록
    function registerQuestion(string memory _title, string memory _question) public payable {
        require(msg.value==200000000000000000);
        // questions[_title] = board(globalNum++, _title, _question, msg.sender, Status.signUp, Answer[](0), 0);
        questions[_title].title = _title;
        questions[_title].question = _question;
        questions[_title].registrant = msg.sender;
        questions[_title].now = Status.signUp;
    }

    //질문 보기
    function viewQuestion(string memory _title) public view returns(uint, string memory, string memory, address, Status, uint){
        return (questions[_title].num, questions[_title].title, questions[_title].question, questions[_title].registrant, questions[_title].now, questions[_title].aCount);
    }

    //답변달기
    function registerAnswer(string memory _title, string memory _a) public payable {
        require(msg.value==100000000000000000);
        require(msg.sender!=questions[_title].registrant);
        require(questions[_title].now != Status.cancel);
        //questions[_title].answers.push(Answer(questions[_title].aCount+1 , msg.sender, _a, false));
        questions[_title].answers[msg.sender] = Answer(questions[_title].aCount+1 , msg.sender, _a, false);
        questions[_title].aCount++;

        if(questions[_title].now == Status.signUp) questions[_title].now = Status.enrolling;    //상태변경경
    }

    //답변 쳬택
    function selectAnswer(string memory _title, uint _idx, address adr) public {
        require(msg.sender == questions[_title].registrant);

         questions[_title].answers[adr].selected == true;
         payable(questions[_title].answers[adr].answer).transfer(125000000000000000);
    }

    //질문 취소
    function cancel(string memory _title) public {
        require(msg.sender == questions[_title].registrant);
        require(questions[_title].now == Status.signUp);

        questions[_title].now = Status.cancel;    //상태변경
    }

    //내 답변 쳬택 확인인
    function viewAnswer(string memory _title) public view returns(bool) {
        return(questions[_title].answers[msg.sender].selected);
    }
}

/*
질문하고 답변하는 질의응답 게시판을 만드세요. 게시판은 번호, 제목, 질문 내용, 질의자, 현재 상태 그리고 답변 내용과 답변자로 이루어져 있습니다.

상태는 질문 등록, 취소, 답변 등록중, 완료가 있다.

모든 유저는 질문자도 답변자도 될 수 있다. 질의응답 과정은 평범하다. 질문자가 질문을 등록한 후에, 답변자가 답변을 다는 것이다. 단 질문자는 스스로의 질문에 답할 수 없다. 

질문자가 등록하면 질문 등록 상태가 된다. 복수의 답변자들이 한 질문에 답변을 등록할 수 있고 1개의 답변이라도 등록되면 그때부터 답변 등록중 상태가 된다. 그 중 질문자가 원하는 답변을 채택하면 완료 상태가 된다. 답변자는 한 질문에 대해 답변은 1개만 등록할 수 있다.

질문할 때는 0.2eth가 답변할 때는 0.1eth가 요구된다. 돈이 충분치 않으면 충전기능을 이용해야한다. 답변이 채택되면 0.125eth를 돌려받는다. 답변 채택은 오직 질문자만 가능하고 여러개의 답변을 채택할 수 있다. 

질문자가 스스로 질문에 대한 답변이 필요없다고 느껴지면 취소할 수 있다. 하지만, 본인의 질문에 답변이 이미 달려있는 상태라면 취소할 수 없다. 

모든 유저들은 이 시스템에 있는 질의응답들의 각 현황을 검색하여 찾아볼 수 있어야 하고, 또 자신이 한 질문이나 답변 역시 볼 수 있어야 한다. 

+) 1분동안 답변이 등록되지 않으면 자동으로 취소상태로 변경되게 하시오.

+) 10eth 이상 한번에 충전하면 금액의 10%를 보너스로 충전할 수 있게 하는 기능을 구현하시오.

+) 해당 시스템의 지속가능성을 위해 질문, 답변시 요구되는 금액을 수정하시오
*/