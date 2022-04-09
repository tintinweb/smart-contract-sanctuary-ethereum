/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

pragma solidity ^0.4.17;

contract Inbox {
    string public message;

    function Inbox(string initialMessage) public {
        message = initialMessage;        
    }

    function setMessage(string newMessage) public returns(string) {
        message = newMessage;
        return message;

    }

    function getMessage() public view returns(string) {
        return message;
    }
}