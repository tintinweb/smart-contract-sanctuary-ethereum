/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

//payable 어려워요 ..
contract AAA{
    enum Status {enroll, cancel, response,complete}
    
    struct Board {
        uint num;
        string q_title;
        string q_contents;
        address questioner;
        Status status;
        address[] answerer;
        string[] a_contents;
    }

    mapping(string => Board) boards;
    uint index;
    function setQuestion(string memory _title, string memory _contents) public payable {
        require(msg.value == 10**18);
        boards[_title].num = index++;
        boards[_title].q_title = _title;
        boards[_title].q_contents = _contents;
        boards[_title].questioner = msg.sender;
        boards[_title].status = Status.enroll;
        
    }

    function setAnswer(string memory _title, string memory _contents) public payable{
        require(msg.value == 10**18);
        require(msg.sender != boards[_title].questioner);
        for(uint i=0;i<boards[_title].answerer.length;i++){
            if(boards[_title].answerer[i] == msg.sender){
                return;
            }
        }
        boards[_title].a_contents.push(_contents);
        boards[_title].answerer.push(msg.sender);
        boards[_title].status = Status.response;

    }

    function choiceAnswer(string memory _title,address payable _to) public {
        require(boards[_title].questioner == msg.sender);
        boards[_title].status = Status.complete;
        _to.transfer(10**18);
    }

    function cancelQuestion(string memory _title) public {
        if(boards[_title].status != Status.response){
            boards[_title].status = Status.cancel;
        }
    }

    function getQuestion(string memory _title) public view returns(Board memory){
        return boards[_title];
    }






}