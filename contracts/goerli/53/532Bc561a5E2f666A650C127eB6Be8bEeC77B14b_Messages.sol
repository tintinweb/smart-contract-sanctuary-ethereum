/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

//spdx-lICENSE-Identifier: MIT

// YOu can use any identifier and version of solidity
pragma solidity >=0.7.8 <0.9.0;

contract Messages{
    address public owner;

    string[] public messages;

    constructor(){
        owner=msg.sender;
    }

    function sendMessage(string memory _message)public{
        messages.push(_message);
    }

    function getMessages() public view returns(string[] memory){
        return messages;
    }
}