/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

pragma solidity ^0.8.17;

contract MessageStorage {
    string private message;

    constructor (string memory initialMessage) {
        message = initialMessage;
    }

    function getMessage() public view returns(string memory) {
        return message;
    }
}