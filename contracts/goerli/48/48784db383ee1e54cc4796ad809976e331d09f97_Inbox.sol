/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// linter warnings (red underline) about pragma version can igonored!
// contract code will go here
pragma solidity ^0.4.17;

contract Inbox {
    string public message;

    function Inbox(string initialMessage) public {
        // 跟 contract 同名，會在部署的時後被呼叫
        message = initialMessage;
    }

    function setMessage(string newMessage) public {
        message = newMessage;
    }
}