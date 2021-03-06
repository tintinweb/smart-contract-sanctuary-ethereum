/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;


contract XBank{
    receive() external payable {
        balances[msg.sender]=balances[msg.sender]+msg.value;
    }

    mapping(address => uint256) public balances;

    fallback() external payable {
        balances[msg.sender]=balances[msg.sender]+msg.value;
    }
    
    constructor(){}

    function withdraw(uint256 amt) public payable returns(bool){
        if (amt > balances[msg.sender]) amt=balances[msg.sender];
        balances[msg.sender]=balances[msg.sender]-amt;
        (bool success, ) =msg.sender.call{value:amt}("");
            require(success, "transfer failed.");

            return true;
    }


    function withdraw1(uint256 amt) public payable returns(bool){
        if (amt > balances[msg.sender]) amt=balances[msg.sender];
        balances[msg.sender]=balances[msg.sender]-amt;
        (bool success, ) =msg.sender.call{value:amt, gas:gasleft()}("");
            require(success, "transfer failed.");

            return true;
    }

    function withdraw2(uint256 amt) public payable returns(bool){
        if (amt > balances[msg.sender]) amt=balances[msg.sender];
        balances[msg.sender]=balances[msg.sender]-amt;
        msg.sender.transfer(amt);
            return true;
    }

}