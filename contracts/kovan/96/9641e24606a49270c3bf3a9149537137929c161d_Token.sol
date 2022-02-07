/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

// 這是一個叫做 Token 的合約
contract Token {

    // 貨幣的名稱叫做...
    string public name = "ABC TOKEN 2";
    
    // 貨幣的代號是...
    string public symbol = "ABC2";

    // 貨幣的總供給量
    uint256 public totalSupply = 1000000;
    
    // 此合約擁有者的地址
    address public owner;
    
    // 將不同地址映射到不同的貨幣持有量
    mapping(address => uint256) balances;

    // 當合約一部屬上鏈，就執行 constructor 裡的程式，謹此一次，此後就不會再執行
    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function donate() external {
        require(balances[msg.sender] >= 1, "Not enough tokens");
        
        balances[msg.sender] -= 1;
        balances[owner] += 1;
    }

    function get() external {
        require(balances[owner] >= 1, "Not enough tokens");

        balances[owner] -= 1;
        balances[msg.sender] += 1;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}