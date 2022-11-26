/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

pragma solidity ^0.8.17;
//SPDX-License-Identifier: MIT

contract Token {

    mapping(address => bool) private blacklist;
    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender); _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function add_blacklist(address wallet) public onlyOwner() {
        blacklist[wallet] = true;
    }

}