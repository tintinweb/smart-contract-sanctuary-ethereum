/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract  SimpleStorage{
    string  message;
    constructor() payable{}

    function all_to_user()public returns(string memory){
        payable(msg.sender).transfer(address(this).balance);
        return "all_to_user ok";
    }

    function pay_to_contract() public payable returns(uint,uint){
        return (msg.value,address(this).balance);
    }
    function set_msg(string calldata _msg) public returns(uint){
        message = _msg;
        return msg.sender.balance;
    }
    function get_msg() public view returns(string memory){
        return message;
    }
}