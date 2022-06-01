/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract sunprotocol{

    uint password = 123;
    string bank;
    mapping(address => User) address_user;
    event event_savemoney( address userAddress, string userName,uint256 balance, uint256 interest);
    event event_receive(address userAddress, uint256 value);
    
    constructor(string memory name){
        bank = name;
    }

    struct User{
        string user_name;
        uint256 user_balance;
        uint256 user_interest;
    }

    function SaveMoney(string memory user_name, uint256 value)external payable{
    
        User storage u = address_user[msg.sender];
        u.user_name = user_name;
        u.user_balance += value;
        u.user_interest = u.user_balance/10;

        emit event_savemoney(msg.sender, user_name, u.user_balance, u.user_interest);
    }

    function CheckBalance()external view HaveMoney returns(uint256) {
        return address_user[msg.sender].user_balance;
    }


    modifier HaveMoney(){
        require(address_user[msg.sender].user_balance != 0, "You are Emtpy!!");
        _;
    }

    function Destory(uint pass_word) external {
        if(pass_word == password){
            selfdestruct(payable(msg.sender));
        }
    }

    fallback()external payable{

    }

    receive()external payable{
        address_user[msg.sender].user_balance += msg.value;
        emit event_receive(msg.sender,msg.value);
    }
}