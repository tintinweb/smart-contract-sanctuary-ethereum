/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Dummy {
    address public owner;
    uint _value;

    constructor(uint value) {
        owner = msg.sender;
        _value = value;
    }

    function get() payable external returns(uint){
        return _value;
    }
}