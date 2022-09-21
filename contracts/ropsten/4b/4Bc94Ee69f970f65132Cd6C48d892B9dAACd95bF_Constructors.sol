/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract Constructors{
    string public name;
    constructor (string memory _name){
        name = _name;
    }
}