/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1; //กำหนด version ที่จะใช้
contract Greetings { 
    string public message; //ประกาศตัวแปล message
    event SetMessage(string _message);
    constructor(string memory _initialMessage) {
        
        message = _initialMessage; 
    } 
    function setMessage(string memory _newMessage) public {
        message = _newMessage; 
        emit SetMessage(_newMessage); //ส่ง event setmessage 
    }
}