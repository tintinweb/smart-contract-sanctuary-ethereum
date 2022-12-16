/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TestMint {
    mapping(address => uint256) private _balances;
    function balanceOf(address owner) public view returns (uint256 balance) {
        require(owner != address(0), "Owner can't be zero");
        return _balances[owner];
    }

    function mint() public{
        require (balanceOf(msg.sender) < 5, "It's too much bro...");
        _balances[msg.sender]++;
    }
}