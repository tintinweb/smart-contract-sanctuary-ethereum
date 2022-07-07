/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT
// File: contracts/Solidity Contracts/构造函数.sol



pragma solidity ^0.8.6;

contract testConstructor {
    address public owner;
    string public name;
    string public symbol;
    uint public totalSupply;
    constructor(
    string memory _name, 
    string memory _symbol, 
    uint _totalSupply
    ) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
    }
}