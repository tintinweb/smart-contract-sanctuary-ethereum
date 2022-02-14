/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.4.23;

contract MsgBoard{
    string public message;
    int public num;
    int public people;

    function init_board(string init_msg) public{
        message = init_msg;
    }

    function edit_msg(string _edit_msg) public{
        message = _edit_msg;
    }

    function show_msg() public view{
        message = 'abck';
    }

    function pay() public payable{
        people++;
    }

}