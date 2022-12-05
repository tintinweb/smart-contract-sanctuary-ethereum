/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;


contract AAA {

    enum Status{registration, cancellation, registrationing, completion}

    struct post {
        uint number;
        string title;
        string questions;
        string questioner;
        string answer;
        string answerer;
        Status status;
    }

    mapping(address => post) posts;
    
    //등록
   function setpost(uint _number, string memory _title, string memory _questions, string memory _questioner) public {
        posts[msg.sender].number = _number;
        posts[msg.sender].title = _title;
        posts[msg.sender].questions = _questions;
        posts[msg.sender].questioner = _questioner;
        posts[msg.sender].status = Status.registration;
    }
    
    //불러오기
     function getpost(address _a) public view returns(uint, string memory, string memory) {
        return (posts[_a].number, posts[_a].title, posts[_a].questions);
    }
/*
    //답변하기
     function answer1(string memory _title, string memory _answer) public {
        require(posts[_title].status == Status.registration);
        posts[_title].answer = _answer;
        posts[_title].status = Status.registrationing;
        posts[_title].answerer = msg.sender; 
        
    }*/
}