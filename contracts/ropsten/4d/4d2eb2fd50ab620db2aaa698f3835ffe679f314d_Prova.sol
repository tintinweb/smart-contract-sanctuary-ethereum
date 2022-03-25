/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Prova{

    function deposit() public payable returns(uint){
        return msg.value;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }


}