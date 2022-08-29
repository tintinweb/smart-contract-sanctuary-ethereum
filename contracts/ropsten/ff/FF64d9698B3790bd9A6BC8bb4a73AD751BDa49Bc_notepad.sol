/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract notepad {
    struct Note {
        string text;
        uint256 date;
    }

    mapping(address => Note[]) _notepad;

    function fetch(address _address) public view returns (Note[] memory) {
        return _notepad[_address];
    }

    function update(address _address, Note memory _note) public {
        _notepad[_address].push(_note);
    }

    function remove(address _address) public {
        delete _notepad[_address];
    }
}