/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Sample {
    string private _pk; 
    address private _addr;

    constructor(string memory pk){
        _pk = pk;
        _addr = msg.sender;
    }
    function getpk() public view returns (string memory) {
        if (_addr == msg.sender) return _pk;
        return "not access!";
    }
}