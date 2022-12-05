/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Homework {
    // enum Status {
    //     Enrolled, Canceled, Registerging, Completed
    // }

    // struct Answer {
    //     address addr;
    //     string content;
    //     bool isSelected;
    // }

    // struct Board {
    //     uint id;
    //     string title;
    //     string content;
    //     address by;
    //     Status status;
    //     Answer[] answerList;
    // }
    // uint idIndex;

    // mapping(string => Board) boardByTitle;
    // mapping(address => uint[]) boardByAddr;
    // mapping(Status => uint[]) boardByStatus;

    // function enroll(string memory _title, string memory _content) payable public {
    //     require(msg.value == 0.2 * (10**18));
    //     boardByAddr[msg.sender].push(idIndex + 1);
    //     boardByStatus[Status.Enrolled].push(idIndex + 1);
    //     boardByTitle[_title] = Board(++idIndex, _title, _content, msg.sender, Status.Enrolled, new Answer[](0));
    // }

    // function answer(string memory _title, string memory _answer) public payable {
    //     require(msg.value == 0.1 * (10**18));
    //     require(boardByTitle[_title].status != Status.Canceled);
    //     if(boardByTitle[_title].answerList.length == 0){
    //         boardByTitle[_title].status = Status.Registerging;
    //         boardByStatus[Status.Registerging].push(boardByTitle[_title].id);
    //     }
    //     boardByTitle[_title].answerList.push(Answer(msg.sender, _answer, false));
    // }

    // function cancel(string memory _title) public {
    //     require(boardByTitle[_title].answerList.length == 0);
    //     boardByTitle[_title].status = Status.Canceled;
    //     boardByStatus[Status.Canceled].push(boardByTitle[_title].id);
    // }

}