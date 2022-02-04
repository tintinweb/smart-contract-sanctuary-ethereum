/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    string public message;

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }

    function retrieve() public view returns (string memory){
        return message;
    }
}