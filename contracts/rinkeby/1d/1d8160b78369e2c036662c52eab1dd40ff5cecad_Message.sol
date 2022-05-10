/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Message {
    string message;

    function setMessage(string calldata _newMessage) public {
        message = _newMessage;
    }

    function getMessage() public view returns(string memory){
        return message;
    }
}