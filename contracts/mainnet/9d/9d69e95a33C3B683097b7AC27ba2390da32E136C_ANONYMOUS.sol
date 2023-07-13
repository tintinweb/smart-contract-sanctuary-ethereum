/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

/**

Tired of scams $ANON?

https://anonymous.wf

https://t.me/anon_portal


**/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.20;

contract ANONYMOUS {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    address public taxReceiver;
    uint256 public buyTaxPercentage;
    uint256 public sellTaxPercentage;
    uint256 public maxWalletPercentage;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        name = "ANONYMOUS";
        symbol = "ANON";
        decimals = 18;
        totalSupply = 1000000000 * 10 ** uint256(decimals); // Total supply of 1,000,000,000 tokens
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        taxReceiver = 0x44f74A41A64B2B4182d1a40BBCE09D011A26F988; // Update with the desired tax receiver address
        buyTaxPercentage = 20; // 20% buy tax
        sellTaxPercentage = 20; // 20% sell tax
        maxWalletPercentage = 3; // Maximum wallet limit of 3%
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(
            balanceOf[to] + value <= (totalSupply * maxWalletPercentage) / 100,
            "Exceeds maximum wallet limit"
        );

        uint256 taxAmount;
        if (msg.sender == owner || to == owner) {
            // Buy or sell transaction
            taxAmount = (value * sellTaxPercentage) / 100;
        } else {
            // Regular transfer
            taxAmount = (value * buyTaxPercentage) / 100;
        }

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value - taxAmount;
        balanceOf[taxReceiver] += taxAmount;

        emit Transfer(msg.sender, to, value);
        emit Transfer(msg.sender, taxReceiver, taxAmount);

        return true;
    }

    function renounceOwnership() external {
        require(msg.sender == owner, "Only the owner can renounce ownership");
        owner = address(0);
    }

    function changeBuyAndSellTaxPercentage(uint256 newPercentage) external {
        require(msg.sender == owner, "Only the owner can change the tax percentage");
        require(newPercentage <= 100, "Invalid percentage");

        buyTaxPercentage = newPercentage;
        sellTaxPercentage = newPercentage;
    }

    function changeMaxWalletPercentage(uint256 newPercentage) external {
        require(msg.sender == owner, "Only the owner can change the max wallet percentage");
        require(newPercentage <= 100, "Invalid percentage");

        maxWalletPercentage = newPercentage;
    }
}