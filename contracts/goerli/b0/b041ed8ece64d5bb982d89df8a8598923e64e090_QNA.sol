/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
//20221205

contract QNA {
    struct board {
        string title;
        string qc;
        address Q;
        string state;
        string[] ac;
        address[] A;
    }
    uint index = 1;
    string[] States = ["registered", "cancel", "ing", "end"];

    mapping(uint => board) Boards;

    function register(string memory _title, string memory _qc) public payable {
        require(msg.sender.balance >= 2*10**17);
        Boards[index].title = _title;
        Boards[index].qc = _qc;
        Boards[index].Q = msg.sender;
        Boards[index].state = States[0];
    }

    function answer(uint ind, string memory _ac) public {
        require(msg.sender.balance >= 1*10**17);
        Boards[ind].ac.push(_ac);
        Boards[ind].A.push(msg.sender);
        if(Boards[ind].ac.length >= 1) {
            Boards[ind].state = States[2];
        }
    }
}