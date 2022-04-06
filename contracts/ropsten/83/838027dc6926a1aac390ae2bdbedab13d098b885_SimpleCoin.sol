/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// amount in existence
// ability to store a balance
// ability to transfer to others

contract SimpleCoin {

    address public owner;
    uint public totalSupply;
    string private _name;

    // set up balances mapping
    // a mapping is like a hash table, or dictionary
    // or like a two-column spreadsheet
    // index -> value
    mapping(address => uint) private _balances;
    constructor() {

        // msg.sender is the account that digitally signed the transaction
        owner = msg.sender;

        // amount
        // make a SimpleCoin where I have 1000 of them
        totalSupply = 1000;

        // name
        _name = "SIM";

        // assign all of the total supply to the owner
        _balances[owner] = totalSupply;
    }
        // and can transfer them to others

    function balanceOf(address account) public view returns(uint) {
        return _balances[account];
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function transfer(address account, uint amount) public returns(bool) {
        address from = msg.sender;
        address to = account;
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount;

        return true;
    }
}