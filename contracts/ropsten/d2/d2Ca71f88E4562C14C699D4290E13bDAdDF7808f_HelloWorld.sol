/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

pragma solidity ^0.8.13;

contract HelloWorld {
    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        message = newMessage;
    }
}