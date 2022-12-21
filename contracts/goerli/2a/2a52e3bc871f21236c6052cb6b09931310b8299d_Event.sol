/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Event{
    event balance(address account,string message,uint value);
    function setData(uint _val) public{
        emit balance(msg.sender,"has value",_val);
    }
    event chat(address indexed _from,address _to,string message);
    function sendMe(address  _to,string memory _message) public{
        emit chat(msg.sender,_to,_message);
    }
}