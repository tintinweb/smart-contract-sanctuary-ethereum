/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract testingnow {
    string message = "how to";
    function read() public view returns(string memory) {
        return message;
    }

    function write(string memory _message) public {
        message = _message;
    }
}