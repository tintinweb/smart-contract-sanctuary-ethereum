/**
 *Submitted for verification at Etherscan.io on 2022-10-24
*/

pragma solidity ^0.8.17;

contract HelloWorld {
    string public message;

    constructor(string memory initialMessage) {
        message = initialMessage;
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }

}