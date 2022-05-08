/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract HelloWorld {
    string private message;
    
    constructor() {
        message = "Hello World!";
    }

    function getMessage() external view returns(string memory) {
        return message;
    }

    function setMessage(string calldata newMessage) public {
        message = newMessage;
    }

    function sum(uint8 a, uint8 b) external pure returns (uint) {
        return a + b;
    }

    function byteToString() public pure returns (string memory) {
        bytes32 _message = "Hello World!";
        return bytes32ToString(_message);
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;

        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }

        bytes memory bytesArray = new bytes(i);

        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }

        return string(bytesArray);
    }
}