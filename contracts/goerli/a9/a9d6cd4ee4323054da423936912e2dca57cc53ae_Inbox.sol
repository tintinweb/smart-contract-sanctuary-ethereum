/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

pragma solidity ^0.4.17;

contract Inbox {
    string public message;

    constructor(string initialMessage) public {
        message = initialMessage;
    }

    function setMessage(string newMessage) public {
        message = newMessage;
    }

    function doMath(int a, int b) public pure {
        a + b;
        b - a;
        a * b;
        a == 0;
    }

}