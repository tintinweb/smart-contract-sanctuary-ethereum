/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SingleTokenZhang {
    string public name = "My First CryptoCurrency";
    string public symbol = "OPT";

    uint256 public totalSupply = 1000000;

    address public owner;

    mapping(address => uint256) balances; // 存储额度

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) external payable  {
        require(balances[msg.sender] >= amount, "Not enough balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }

    fallback() external payable {
      
    }

    receive() external payable {
        
    }
}