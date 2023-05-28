/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
// Frontrun AI Token
/*

8888888888                        888                                           d8888 8888888 
888                               888                                          d88888   888   
888                               888                                         d88P888   888   
8888888 888d888  .d88b.  88888b.  888888 888d888 888  888 88888b.            d88P 888   888   
888     888P"   d88""88b 888 "88b 888    888P"   888  888 888 "88b          d88P  888   888   
888     888     888  888 888  888 888    888     888  888 888  888         d88P   888   888   
888     888     Y88..88P 888  888 Y88b.  888     Y88b 888 888  888        d8888888888   888   
888     888      "Y88P"  888  888  "Y888 888      "Y88888 888  888       d88P     888 8888888 

0100011001110010011011110110111001110100011100100111010101101110  0100000101001001   V. 0.14a                                                                                          
 */                                                                                        
                                                                                              

pragma solidity ^0.8.0;

contract Frontrun {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    constructor() {
        name = "Frontrun AI";
        symbol = "FRUN";
        decimals = 18;
        totalSupply = 1_000_000_000_000 * 10**uint256(decimals); // 1 trillion tokens with 18 decimal places
        balanceOf[msg.sender] = totalSupply;
    }
    
    modifier canTransfer() {
        require(msg.sender == tx.origin, "Transfer not allowed");
        _;
    }
    
    function transfer(address to, uint256 amount) public canTransfer returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        
        return true;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}