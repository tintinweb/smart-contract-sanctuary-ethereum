/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT;

pragma solidity >= 0.5.0 < 0.9.0;

contract MyToken {
    uint public supply;
    address public owner;
    mapping(address => uint) public balance;

    constructor(uint _supply) public {
        supply = _supply;
        owner = msg.sender;
        balance[owner] = supply;
    }

    function transfer(address _to, uint _amount) public {
        require(msg.sender == owner, "Only owner can send Token");
        require(balance[owner] >= _amount, "Insufficient Amount");

        balance[owner] -= _amount;
        balance[_to] += _amount;
    }
}