/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract csieBoard {
    string public message;
    int public persons = 0;

    constructor(string memory initMessage) public {
        message = initMessage;
    }

    function editMessage(string memory newMessage) public {
        message = newMessage;
    }

    function showMessage() public view returns(string memory) {
        return message;
    }

    function pay() public payable {
        persons += 1;
    }
}