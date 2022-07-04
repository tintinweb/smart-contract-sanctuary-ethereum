/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract token{
    string public name = "Community Token";
    string public symbol = "COMT";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1000;

    mapping(address => uint256)public balanceOf;

        constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalSupply){
            name = _name;
            symbol = _symbol;
            decimals = _decimals;
            totalSupply = _totalSupply;
            balanceOf[msg.sender] = totalSupply;

        }
}