// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Forum {
    string[] public allMessages;
    string[][] public allComments;
    uint public messageNumber = 0;
    uint public commentNumber = 0;

    mapping (uint => uint) likeMessageMap;
    mapping (uint => uint) likeCommentMap;
    mapping (uint => uint) dislikeMessageMap;
    mapping (uint => uint) dislikeCommentMap;

    //Errors

    error Forum__MessageNumberExceeded();

    function sendMessage(string memory _myMessage) public{
        allMessages.push(_myMessage);
        messageNumber++;
    }

    function readMessage(uint _messageNumber) public view returns (string memory){
        if(_messageNumber > messageNumber) {
            revert Forum__MessageNumberExceeded();
        }
        return allMessages[_messageNumber];
    }

    function getMessageNumber() public view returns(uint){
        return messageNumber;
    }

    function sendComment(uint _messageNumber, string memory _myComment) public{
        allComments.push([allMessages[_messageNumber], _myComment]);
        commentNumber++;
    }

    function likeMessage(uint _messageNumber) public{
        likeMessageMap[_messageNumber]++;
    }

    function likeComment(uint _messageNumber) public{
        likeCommentMap[_messageNumber]++;
    }
    function dislikeMessage(uint _messageNumber) public{
        dislikeMessageMap[_messageNumber]++;
    }

    function dislikeComment(uint _messageNumber) public{
        dislikeCommentMap[_messageNumber]++;
    }
}