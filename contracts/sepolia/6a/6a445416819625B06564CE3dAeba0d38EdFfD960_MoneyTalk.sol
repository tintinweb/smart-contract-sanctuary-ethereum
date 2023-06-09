/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract MoneyTalk {
    address owner;

    struct Note {
        string text;
        uint tipFee;
    }

    Note[] public notes;

    event Said(string Quote, uint withFee, uint index);

    constructor() {
        owner = msg.sender;
    }

    function write(string calldata note) public payable {
        notes.push(Note(note, msg.value));
        emit Said(note, msg.value, notes.length - 1);
    }

    function withdrawAll() external {
        payable(owner).transfer(address(this).balance);
    }
}