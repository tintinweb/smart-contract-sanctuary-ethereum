/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity ^0.4.17;

contract Inbox{
    string public message;

    function Inbox(string InitialMessage) public{
        message = InitialMessage;
    }

    function setMessage(string newMessage) public{
        message = newMessage;
    }
}