/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract AIGrom {
    string public name = "AIGrom";
    string public symbol = "AIG";
    uint256 public totalSupply = 10000000000000000000000000;
    uint8 public decimals = 18;
    mapping (address => uint256) public balanceOf;

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value && _value > 0, "Insufficient balance.");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
    }
}