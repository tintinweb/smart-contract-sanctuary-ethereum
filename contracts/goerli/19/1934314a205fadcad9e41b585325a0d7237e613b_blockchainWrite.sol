/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

//SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.8.0;

contract blockchainWrite {
    string text;
    function write (string calldata _text) public {
        text = _text;
    }

    function read () public view returns (string memory) {
        return text;
    }
}