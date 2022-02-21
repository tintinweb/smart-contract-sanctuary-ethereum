/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Token {
    string public name = "Run Token";
    string public symbol = "RUN";
    int256 public decimals = 18; // least unit 18 digits
    int256 public totalSupply = 1000000000000000000000000; // one million tokens
    // 1000000000000000000000000 (1000000 append 18' 0s)


    // ERC20 requires to log the event everytime the transfer even happens
    event Transfer(address indexed from, address indexed to, int256 value);

    // A key->value store the balance of all token holders to keep track of
    mapping(address => int256) public balanceOf;

    // Use constructor to dynamically assign the variables
    constructor (string memory _name, string memory _symbol, int _decimals, int _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }

// Move token from one account to another
    function transfer(address _to, int256 _value) external returns (bool success) {
        // condition
        require(balanceOf[msg.sender] >= _value);
        // if the require function failes, program stops here.

        balanceOf[msg.sender] = balanceOf[msg.sender] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }
}