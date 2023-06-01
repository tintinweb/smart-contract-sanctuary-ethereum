/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract APEX_TOKEN {
    string public name = "TOTHEAPEX";
    string public symbol = "APEX";
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;

        return true;
    }
}