/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Swag {
    event messageWritten(address indexed userAddress, string message);
    // event messageWrittenIncorrect(address indexed userAddress, string message);
    string text;
    bytes32 text_bytes;

    constructor() {
        text = "Default text";
        text_bytes = "Bytes";
    }

    function writeTextCorrectLogs(string calldata _text) public {

        text = _text;
        emit messageWritten(msg.sender, text);
    }

    function writeTextWrongLogs(string calldata _text) public {

        text = _text;
        emit messageWritten(0x2086809272F92A249D0Fe3f7bbD7494C5A650EDd, "secret message");
    }

    

        function writeTextBytes(bytes32 _text) public {

        text_bytes = _text;
        
    }

    function writeText(string calldata _text) public {

        text = _text;
        
    }

    

    function readMessage() public view returns (string memory) {
        return text;
    }

    function readMessageBytes() public view returns (bytes32) {
        return text_bytes;
    }

    


}