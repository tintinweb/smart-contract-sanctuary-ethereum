/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MyToken {
    string public name = "ABCDE";
    string public symbol = "ABC";
    uint8 public decimals = 8;
    uint256 public totalSupply = 1000000000 * 10**uint256(decimals);

    address public owner;
    address public feeWallet;
    uint256 public taxPercentage = 2;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
        feeWallet = 0x7d6Fa9fF089dC63068Cd1fD991f35a3479129fbd;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Not enough balance");
        uint256 fee = (value * taxPercentage) / 100;
        balanceOf[msg.sender] -= value;
        balanceOf[to] += (value - fee);
        balanceOf[feeWallet] += fee;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function changeFeeWallet(address newFeeWallet) public {
        require(msg.sender == owner, "Only owner can change fee wallet");
        feeWallet = newFeeWallet;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Only owner can transfer ownership");
        owner = newOwner;
    }

    function changeTax(uint256 newTaxPercentage) public {
        require(msg.sender == owner, "Only owner can change tax");
        require(newTaxPercentage <= 10, "Tax percentage must be <= 10");
        taxPercentage = newTaxPercentage;
    }

    function renounce() public {
        require(msg.sender == owner, "Only owner can renounce ownership");
        owner = address(0);
    }
}