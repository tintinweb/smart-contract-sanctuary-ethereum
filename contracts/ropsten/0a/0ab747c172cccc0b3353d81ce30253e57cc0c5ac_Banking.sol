/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Banking
{

    mapping(address => uint) public user_balance;

    function transfer_acc(address payable _arg) public payable returns(bool)
    {
        _arg.transfer(msg.value);
        user_balance[_arg] += msg.value;
        return true;
    }

    function get_balance() public view returns(uint)
    {
        return user_balance[msg.sender];
    }

}


//Functions Visiblity in Solidity Public, Private, Internal and External
//Payable Function for Writing in SmartContract, View Function for Reading from SmartContract