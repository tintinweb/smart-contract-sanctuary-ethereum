/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

pragma solidity ^0.4.26;

contract Inbox {
    string public message;

    constructor (string initialMessage) public {
        message = initialMessage;
    }

    function setMessage(string newMessage) public {
        message = newMessage;
    }

}