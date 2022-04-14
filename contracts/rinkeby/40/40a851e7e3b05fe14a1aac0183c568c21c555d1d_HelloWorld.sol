/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;
contract HelloWorld {
    event UpdatedMessages(string oldStr,string newStr);
    string public message;
    constructor(string memory _message){
        message = _message;
    }
    function viewMessage() public view returns(string memory){
        return message;
    }
    function update(string memory newMsg) public {
        string memory oldMsg = message;
        message = newMsg;
        emit UpdatedMessages(oldMsg,newMsg);
    }
}