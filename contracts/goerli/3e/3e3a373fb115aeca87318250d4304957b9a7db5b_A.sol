/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract A {
    enum Status{
        registered,
        cancel,
        Answering,
        complete
    }

    enum StatusAnswer{
        registered,
        choosed
    }

    struct question {
        uint id;
        address who;
        string text;
        Status status;
        uint timestamp;
        uint answers;
    }


    struct answer {
        address who;
        string text;
        StatusAnswer status;
    }

    mapping(uint => question) Questions;
    mapping(uint => answer[]) Answers;
    uint id;

    function askQuestion(string memory _text)public payable{
        require(msg.value == 2*10**18);
        Questions[++id] = question(++id, msg.sender, _text, Status.registered, block.timestamp, 0);
    }

    function answerQuestion(uint _id, string memory _text)public payable{
        require(msg.value == 10**18);
        require(Questions[_id].status != Status.complete || Questions[_id].status != Status.cancel);
        Questions[_id].status = Status.Answering;
        Answers[_id].push(answer(msg.sender, _text,StatusAnswer.registered));
    }

     function transferTo(address payable _to, uint _amount) public {
        _to.transfer(_amount);
    }

    function chooseQuestion(uint _id, uint _answerId)public {
        require(Questions[_id].status != Status.complete || Questions[_id].status != Status.cancel);
       // transferTo(Answers[_id][_answerId].who,1.25*10**18);
        Questions[_id].status != Status.complete;
    }
}