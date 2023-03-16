/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MyToken {
    string public name = "Locked Almost";
    string public symbol = "LALM";
    uint8 public decimals = 8;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed from, address indexed to, uint256 value);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function transfer(address to, uint256 value) public onlyOwner returns (bool) {
        require(to != address(0), "Invalid address.");
        require(value > 0, "Invalid value.");
        require(balanceOf[msg.sender] >= value, "Insufficient balance.");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        require(to != address(0), "Invalid address.");
        require(value > 0, "Invalid value.");

        balanceOf[to] += value;
        totalSupply += value;
        emit Mint(owner, to, value);
        return true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address.");

        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}