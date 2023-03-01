/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuthorityToken {
    string public name = "Authority Token";
    string public symbol = "AUTH";
    uint8 public decimals = 0;
    uint256 public totalSupply = 1000000000;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address[] public tokenHolders;
    mapping(address => bool) private hasReceivedTokens;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        tokenHolders.push(msg.sender);
        hasReceivedTokens[msg.sender] = true;
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        if (!hasReceivedTokens[to]) {
            tokenHolders.push(to);
            hasReceivedTokens[to] = true;
        }
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Not enough allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        if (!hasReceivedTokens[to]) {
            tokenHolders.push(to);
            hasReceivedTokens[to] = true;
        }
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
   function getTokenHolders() public view returns (address[] memory) {
    uint256 count = 0;
    for (uint256 i = 0; i < tokenHolders.length; i++) {
        if (balanceOf[tokenHolders[i]] > 0) {
            count++;
        }
    }
    address[] memory result = new address[](count);
    uint256 index = 0;
    for (uint256 i = 0; i < tokenHolders.length; i++) {
        if (balanceOf[tokenHolders[i]] > 0) {
            result[index] = tokenHolders[i];
            index++;
        }
    }
    return result;
}

}