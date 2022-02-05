/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity ^0.4.17;

contract Inbox {
    string public message;

    function inbox(string initialMessage) public {
        message = initialMessage;
    }
    
    function setMessage(string newMessage) public {
        message = newMessage;
    }
}