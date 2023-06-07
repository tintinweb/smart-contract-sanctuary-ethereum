/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract MoneyTalk {
    address owner;

    string[] public notes;

    event Said(string, uint);

    constructor() {
        owner = msg.sender;
    }

    function write(string calldata note) public payable {
        notes.push(note);
        emit Said(note, msg.value);
    }

    function withdrawAll() external {
        payable(owner).transfer(address(this).balance);
    }
}