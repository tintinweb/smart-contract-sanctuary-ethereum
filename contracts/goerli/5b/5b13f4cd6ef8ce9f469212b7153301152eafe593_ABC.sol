/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;



contract ABC {
/*
    struct board {
        uint num;
        string title;
        string contents;
        address maker;
        uint state; // 0: 질문등록, 1:취소, 2:답변등록중, 3:완료
        address responser;
        string r_contents;
    }

    mapping(address => board) boards;

    uint i;

    function question(string memory _title, string memory _contents) public {
        boards[msg.sender] = board(i++, _title, _contents, msg.sender, 0, address(0), "");
    }

    function answer(address _maker, string memory _r_contents) public {
        boards[_maker].responser = msg.sender;
        boards[_maker].r_contents = _r_contents;
        boards[_maker].state = 2;
    }

    function getQuestion(address _maker) public view returns(board memory) {
        return boards[_maker];
    }
    */
}