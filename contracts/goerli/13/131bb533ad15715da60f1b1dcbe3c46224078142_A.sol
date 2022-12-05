/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

contract A {

    enum State {q_post, cancle, ans_posting, all_posted}
    struct Board {
        uint b_num;
        string b_title;
        string b_content;
        address b_user;
        State state;
        string b_ans;
        address b_ans_addr;
    }
    mapping(string => Board) Boards;
    struct User {
        string name;
        address addr;
    }
    mapping(address => User) users;

    function setUser(string memory _name) public {
        users[msg.sender] = User(_name, msg.sender);
    }

    uint index;

    function setQna(string memory _title, string memory _content) public payable {
        require(msg.value == 10**17 * 2);
        // Boards[_title] = Board(index++, _title, _content, msg.sender, State.q_post, string(NULL), address(0));
    }


    function setAns(string memory _title, string memory _content) public payable{
            require(msg.value == 10**17, "error!!");
            Boards[_title].b_ans = _content;
            Boards[_title].b_ans_addr = msg.sender;
            Boards[_title].state = State.ans_posting;
    }
    

    function ChooseAns(string memory _title, string memory b_ans) public {
        require(msg.sender == Boards[_title].b_user);
        Boards[_title].state = State.all_posted;
        // Users[Boards[_title].b_ans_addr].transfer(125000000000000000);
    }
}