/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;
    library Balances {
    function move(mapping(address => uint256) storage balances, address from, address to, uint amount) internal {
    require(balances[from] >= amount);
    require(balances[to] + amount >= balances[to]);
    balances[from] -= amount;
    balances[to] += amount;
    }
}

contract Token {
    mapping(address => uint256) balances;
    using Balances for *;
    mapping(address => mapping (address => uint256)) allowed;

    event Transfer(address from, address to, uint amount);
    event Approval(address owner, address spender, uint amount);

    function transfer(address to, uint amount) external returns (bool success) {
    balances.move(msg.sender, to, amount);
    emit Transfer(msg.sender, to, amount);
    return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool success) {
    require(allowed[from][msg.sender] >= amount);
    allowed[from][msg.sender] -= amount;
    balances.move(from, to, amount);
    emit Transfer(from, to, amount);
    return true;
    }

    function approve(address spender, uint tokens) external returns (bool success) {
    require(allowed[msg.sender][spender] == 0, "");
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
    }
    function balanceOf(address tokenOwner) external view returns (uint balance) {
    return balances[tokenOwner];
    }
}