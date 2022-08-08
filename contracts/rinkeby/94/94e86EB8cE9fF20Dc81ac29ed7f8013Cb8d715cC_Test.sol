/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

contract Test {
    address public owner;
    string public note;
    event Logo(address _from, uint _timestamp);

    constructor() {
        owner = msg.sender;
    }

    function setTelegram(string memory _note) public {
        note = _note;
        emit Logo(msg.sender, block.timestamp);
    }
}