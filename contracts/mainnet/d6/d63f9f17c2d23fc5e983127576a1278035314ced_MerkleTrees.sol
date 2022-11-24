/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MerkleTrees {

    mapping (address => uint256) public balanceOf;
    string public name = "Merkle Trees";
    string public symbol = "Merkle Trees";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000000000 * (10 ** decimals);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}