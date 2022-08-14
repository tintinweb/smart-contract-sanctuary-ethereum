/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.8.16;

contract Etchat{
    string textchat;

    function Write(string calldata _textchat) public{
        textchat = _textchat;
    }

    function Read() public view returns(string memory){
        return textchat;
    }
}